/* -------------------------------------------------------------------------
 *
 * pg_duration.c
 *
 * -------------------------------------------------------------------------
 */

#include "postgres.h"

#include <math.h>

#include "common/int.h"
#include "fmgr.h"
#include "libpq/pqformat.h"
#include "miscadmin.h"
#include "utils/fmgrprotos.h"

#include "pg_duration.h"

PG_MODULE_MAGIC;

/*
** Input/Output routines
*/
PG_FUNCTION_INFO_V1(duration_in);
PG_FUNCTION_INFO_V1(duration_out);
PG_FUNCTION_INFO_V1(duration_recv);
PG_FUNCTION_INFO_V1(duration_send);

/*
** Indexing routines
*/
PG_FUNCTION_INFO_V1(hash_duration);

/*
** Comparison operators
*/
PG_FUNCTION_INFO_V1(duration_cmp);
PG_FUNCTION_INFO_V1(duration_lt);
PG_FUNCTION_INFO_V1(duration_le);
PG_FUNCTION_INFO_V1(duration_gt);
PG_FUNCTION_INFO_V1(duration_ge);
PG_FUNCTION_INFO_V1(duration_eq);
PG_FUNCTION_INFO_V1(duration_ne);

/*
** Arithmetic operators
*/
PG_FUNCTION_INFO_V1(duration_um);
PG_FUNCTION_INFO_V1(duration_pl);
PG_FUNCTION_INFO_V1(duration_mi);
PG_FUNCTION_INFO_V1(duration_mul);
PG_FUNCTION_INFO_V1(duration_div);

static void EncodeSpecialDuration(const Duration duration, char *str);
static Duration duration_um_internal(const Duration duration);

/*****************************************************************************
 * Input/Output methods
 *****************************************************************************/

Datum
duration_in(PG_FUNCTION_ARGS)
{
	char	   *str = PG_GETARG_CSTRING(0);
	struct Node *escontext = fcinfo->context;
	Duration	result;
	struct pg_itm_in tt,
			   *itm_in = &tt;
	int			dtype;
	int			nf;
	int			range;
	int			dterr;
	char	   *field[MAXDATEFIELDS];
	int			ftype[MAXDATEFIELDS];
	char		workbuf[256];
	DateTimeErrorExtra extra;

	itm_in->tm_year = 0;
	itm_in->tm_mon = 0;
	itm_in->tm_mday = 0;
	itm_in->tm_usec = 0;

	range = INTERVAL_FULL_RANGE;

	dterr = ParseDateTime(str, workbuf, sizeof(workbuf), field,
						  ftype, MAXDATEFIELDS, &nf);
	if (dterr == 0)
		dterr = DecodeInterval(field, ftype, nf, range,
							   &dtype, itm_in);

	/* if those functions think it's a bad format, try ISO8601 style */
	if (dterr == DTERR_BAD_FORMAT)
		dterr = DecodeISO8601Interval(str,
									  &dtype, itm_in);

	if (dterr != 0)
	{
		if (dterr == DTERR_FIELD_OVERFLOW)
			dterr = DTERR_INTERVAL_OVERFLOW;
		DateTimeParseError(dterr, &extra, str, "duration", escontext);
		PG_RETURN_NULL();
	}

	switch (dtype)
	{
		case DTK_DELTA:
			if (itmin2duration(itm_in, &result) != 0)
				ereturn(escontext, (Datum) 0,
						(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
						 errmsg("invalid units for duration")));
			break;

		case DTK_LATE:
			DURATION_NOEND(result);
			break;

		case DTK_EARLY:
			DURATION_NOBEGIN(result);
			break;

		default:
			elog(ERROR, "unexpected dtype %d while parsing duration \"%s\"",
				 dtype, str);
	}

	PG_RETURN_DURATION(result);
}

Datum
duration_out(PG_FUNCTION_ARGS)
{
	Duration	duration = PG_GETARG_DURATION(0);
	char	   *result;
	struct pg_itm tt,
			   *itm = &tt;
	char		buf[MAXDATELEN + 1];

	if (DURATION_NOT_FINITE(duration))
		EncodeSpecialDuration(duration, buf);
	else
	{
		duration2itm(duration, itm);
		EncodeInterval(itm, IntervalStyle, buf);
	}

	result = pstrdup(buf);
	PG_RETURN_CSTRING(result);
}

Datum
duration_recv(PG_FUNCTION_ARGS)
{
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);
	Duration	duration = pq_getmsgint64(buf);

	PG_RETURN_DURATION(duration);
}

Datum
duration_send(PG_FUNCTION_ARGS)
{
	Duration	duration = PG_GETARG_DURATION(0);
	StringInfoData buf;

	pq_begintypsend(&buf);
	pq_sendint64(&buf, duration);
	PG_RETURN_BYTEA_P(pq_endtypsend(&buf));
}

/* duration2itm()
 * Convert an Duration to a pg_itm structure.
 * Note: overflow is not possible, because the pg_itm fields are
 * wide enough for all possible conversion results.
 */
void
duration2itm(Duration duration, struct pg_itm *itm)
{
	TimeOffset	time;
	TimeOffset	tfrac;

	itm->tm_year = 0;
	itm->tm_mon = 0;
	itm->tm_mday = 0;
	time = duration;

	tfrac = time / USECS_PER_HOUR;
	time -= tfrac * USECS_PER_HOUR;
	itm->tm_hour = tfrac;
	tfrac = time / USECS_PER_MINUTE;
	time -= tfrac * USECS_PER_MINUTE;
	itm->tm_min = (int) tfrac;
	tfrac = time / USECS_PER_SEC;
	time -= tfrac * USECS_PER_SEC;
	itm->tm_sec = (int) tfrac;
	itm->tm_usec = (int) time;
}

/* itmin2duration()
 * Convert a pg_itm_in structure to a Duration.
 * Returns 0 if OK, -1 on invalid units.
 */
int
itmin2duration(struct pg_itm_in *itm_in, Duration *duration)
{
	if (itm_in->tm_year != 0 || itm_in->tm_mon != 0 || itm_in->tm_mday != 0)
		return -1;
	*duration = itm_in->tm_usec;
	return 0;
}

static void
EncodeSpecialDuration(const Duration duration, char *str)
{
	if (DURATION_IS_NOBEGIN(duration))
		strcpy(str, EARLY);
	else if (DURATION_IS_NOEND(duration))
		strcpy(str, LATE);
	else						/* shouldn't happen */
		elog(ERROR, "invalid argument for EncodeSpecialDuration");
}

/*****************************************************************************
 *				   Indexing methods
 *****************************************************************************/

Datum
hash_duration(PG_FUNCTION_ARGS)
{
	return hashint8(fcinfo);
}

/*****************************************************************************
 *				   Comparison operators
 *****************************************************************************/

static int
duration_sign(const Duration duration)
{
	if (duration < 0)
		return -1;
	if (duration > 0)
		return 1;
	return 0;
}

Datum
duration_cmp(PG_FUNCTION_ARGS)
{
	Duration	a = PG_GETARG_DURATION(0);
	Duration	b = PG_GETARG_DURATION(1);

	if (a < b)
		PG_RETURN_INT32(-1);
	else if (a > b)
		PG_RETURN_INT32(1);
	else
		PG_RETURN_INT32(0);
}

Datum
duration_lt(PG_FUNCTION_ARGS)
{
	int			cmp = DatumGetInt32(DirectFunctionCall2(duration_cmp,
														PG_GETARG_DATUM(0),
														PG_GETARG_DATUM(1)));

	PG_RETURN_BOOL(cmp < 0);
}

Datum
duration_le(PG_FUNCTION_ARGS)
{
	int			cmp = DatumGetInt32(DirectFunctionCall2(duration_cmp,
														PG_GETARG_DATUM(0),
														PG_GETARG_DATUM(1)));

	PG_RETURN_BOOL(cmp <= 0);
}

Datum
duration_gt(PG_FUNCTION_ARGS)
{
	int			cmp = DatumGetInt32(DirectFunctionCall2(duration_cmp,
														PG_GETARG_DATUM(0),
														PG_GETARG_DATUM(1)));

	PG_RETURN_BOOL(cmp > 0);
}

Datum
duration_ge(PG_FUNCTION_ARGS)
{
	int			cmp = DatumGetInt32(DirectFunctionCall2(duration_cmp,
														PG_GETARG_DATUM(0),
														PG_GETARG_DATUM(1)));

	PG_RETURN_BOOL(cmp >= 0);
}


Datum
duration_eq(PG_FUNCTION_ARGS)
{
	int			cmp = DatumGetInt32(DirectFunctionCall2(duration_cmp,
														PG_GETARG_DATUM(0),
														PG_GETARG_DATUM(1)));

	PG_RETURN_BOOL(cmp == 0);
}

Datum
duration_ne(PG_FUNCTION_ARGS)
{
	int			cmp = DatumGetInt32(DirectFunctionCall2(duration_cmp,
														PG_GETARG_DATUM(0),
														PG_GETARG_DATUM(1)));

	PG_RETURN_BOOL(cmp != 0);
}

/*****************************************************************************
 *				   Arithmetic operators
 *****************************************************************************/

static Duration
duration_um_internal(const Duration duration)
{
	Duration	result;

	if (DURATION_IS_NOBEGIN(duration))
		DURATION_NOEND(result);
	else if (DURATION_IS_NOEND(duration))
		DURATION_NOBEGIN(result);
	else if (pg_sub_s64_overflow(INT64CONST(0), duration, &result) || DURATION_NOT_FINITE(result))
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("duration out of range")));

	return result;
}

Datum
duration_um(PG_FUNCTION_ARGS)
{
	Duration	duration = PG_GETARG_DURATION(0);
	Duration	result = duration_um_internal(duration);

	PG_RETURN_DURATION(result);
}

static Duration
finite_duration_pl(const Duration duration1, const Duration duration2)
{
	Duration	result;

	Assert(!DURATION_NOT_FINITE(duration1));
	Assert(!DURATION_NOT_FINITE(duration2));

	if (pg_add_s64_overflow(duration1, duration2, &result) || DURATION_NOT_FINITE(result))
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("duration out of range")));

	return result;
}

Datum
duration_pl(PG_FUNCTION_ARGS)
{
	Duration	duration1 = PG_GETARG_DURATION(0);
	Duration	duration2 = PG_GETARG_DURATION(1);
	Duration	result;

	/*
	 * Handle infinities.
	 *
	 * We treat anything that amounts to "infinity - infinity" as an error,
	 * since the duration type has nothing equivalent to NaN.
	 */
	if (DURATION_IS_NOBEGIN(duration1))
	{
		if (DURATION_IS_NOEND(duration2))
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("duration out of range")));
		else
			DURATION_NOBEGIN(result);
	}
	else if (DURATION_IS_NOEND(duration1))
	{
		if (DURATION_IS_NOBEGIN(duration2))
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("duration out of range")));
		else
			DURATION_NOEND(result);
	}
	else if (DURATION_NOT_FINITE(duration2))
		result = duration2;

	/*
	 * Handle finite values.
	 */
	else
		result = finite_duration_pl(duration1, duration2);

	PG_RETURN_DURATION(result);
}

static Duration
finite_duration_mi(const Duration duration1, const Duration duration2)
{
	Duration	result;

	Assert(!DURATION_NOT_FINITE(duration1));
	Assert(!DURATION_NOT_FINITE(duration2));

	if (pg_sub_s64_overflow(duration1, duration2, &result) || DURATION_NOT_FINITE(result))
		ereport(ERROR,
				(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
				 errmsg("duration out of range")));

	return result;
}

Datum
duration_mi(PG_FUNCTION_ARGS)
{
	Duration	duration1 = PG_GETARG_DURATION(0);
	Duration	duration2 = PG_GETARG_DURATION(1);
	Duration	result;

	/*
	 * Handle infinities.
	 *
	 * We treat anything that amounts to "infinity - infinity" as an error,
	 * since the duration type has nothing equivalent to NaN.
	 */
	if (DURATION_IS_NOBEGIN(duration1))
	{
		if (DURATION_IS_NOBEGIN(duration2))
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("duration out of range")));
		else
			DURATION_NOBEGIN(result);
	}
	else if (DURATION_IS_NOEND(duration1))
	{
		if (DURATION_IS_NOEND(duration2))
			ereport(ERROR,
					(errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
					 errmsg("duration out of range")));
		else
			DURATION_NOEND(result);
	}
	else if (DURATION_IS_NOBEGIN(duration2))
		DURATION_NOEND(result);
	else if (DURATION_IS_NOEND(duration2))
		DURATION_NOBEGIN(result);
	else
		result = finite_duration_mi(duration1, duration2);

	PG_RETURN_DURATION(result);
}

Datum
duration_mul(PG_FUNCTION_ARGS)
{
	Duration	duration = PG_GETARG_DURATION(0);
	float8		factor = PG_GETARG_FLOAT8(1);
	double		result_double;
	Duration	result;

	/*
	 * Handle NaN and infinities.
	 *
	 * We treat "0 * infinity" and "infinity * 0" as errors, since the
	 * duration type has nothing equivalent to NaN.
	 */
	if (isnan(factor))
		goto out_of_range;

	if (DURATION_NOT_FINITE(duration))
	{
		if (factor == 0.0)
			goto out_of_range;

		if (factor < 0.0)
			result = duration_um_internal(duration);
		else
			result = duration;

		PG_RETURN_DURATION(result);
	}
	if (isinf(factor))
	{
		int			isign = duration_sign(duration);

		if (isign == 0)
			goto out_of_range;

		if (factor * isign < 0)
			DURATION_NOBEGIN(result);
		else
			DURATION_NOEND(result);

		PG_RETURN_DURATION(result);
	}

	result_double = rint(duration * factor);
	if (isnan(result_double) || !FLOAT8_FITS_IN_INT64(result_double))
		goto out_of_range;
	result = (int64) result_double;

	if (DURATION_NOT_FINITE(result))
		goto out_of_range;

	PG_RETURN_DURATION(result);

out_of_range:
	ereport(ERROR,
			errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
			errmsg("duration out of range"));

	PG_RETURN_NULL();			/* keep compiler quiet */
}

Datum
duration_div(PG_FUNCTION_ARGS)
{
	Duration	duration = PG_GETARG_DURATION(0);
	float8		factor = PG_GETARG_FLOAT8(1);
	double		result_double;
	Duration	result;

	if (factor == 0.0)
		ereport(ERROR,
				(errcode(ERRCODE_DIVISION_BY_ZERO),
				 errmsg("division by zero")));

	/*
	 * Handle NaN and infinities.
	 *
	 * We treat "infinity / infinity" as an error, since the duration type has
	 * nothing equivalent to NaN.  Otherwise, dividing by infinity is handled
	 * by the regular division code, causing the result to be set to zero.
	 */
	if (isnan(factor))
		goto out_of_range;

	if (DURATION_NOT_FINITE(duration))
	{
		if (isinf(factor))
			goto out_of_range;

		if (factor < 0.0)
			result = duration_um_internal(duration);
		else
			result = duration;

		PG_RETURN_DURATION(result);
	}

	result_double = rint(duration / factor);
	if (isnan(result_double) || !FLOAT8_FITS_IN_INT64(result_double))
		goto out_of_range;
	result = (int64) result_double;

	if (DURATION_NOT_FINITE(result))
		goto out_of_range;

	PG_RETURN_DURATION(result);

out_of_range:
	ereport(ERROR,
			errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
			errmsg("duration out of range"));

	PG_RETURN_NULL();			/* keep compiler quiet */
}
