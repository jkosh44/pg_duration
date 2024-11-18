/* -------------------------------------------------------------------------
 *
 * pg_duration.c
 *
 * -------------------------------------------------------------------------
 */

#include "postgres.h"

#include "fmgr.h"
#include "libpq/pqformat.h"
#include "miscadmin.h"

#include "pg_duration.h"

PG_MODULE_MAGIC;

/*
** Input/Output routines
*/
PG_FUNCTION_INFO_V1(duration_in);
PG_FUNCTION_INFO_V1(duration_out);
PG_FUNCTION_INFO_V1(duration_recv);
PG_FUNCTION_INFO_V1(duration_send);

/*****************************************************************************
 * Input/Output functions
 *****************************************************************************/

Datum
duration_in(PG_FUNCTION_ARGS)
{
	char	   *str = PG_GETARG_CSTRING(0);
	struct Node	   *escontext = fcinfo->context;
	Duration   result;
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

		default:
			elog(ERROR, "unexpected dtype %d while parsing duration \"%s\"",
				 dtype, str);
	}

	PG_RETURN_DURATION(result);
}

Datum
duration_out(PG_FUNCTION_ARGS)
{
	Duration   span = PG_GETARG_DURATION(0);
	char	   *result;
	struct pg_itm tt,
			   *itm = &tt;
	char		buf[MAXDATELEN + 1];

	duration2itm(span, itm);
	EncodeInterval(itm, IntervalStyle, buf);

	result = pstrdup(buf);
	PG_RETURN_CSTRING(result);
}

Datum
duration_recv(PG_FUNCTION_ARGS)
{
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);
	Duration   duration = pq_getmsgint64(buf);

	PG_RETURN_DURATION(duration);
}

Datum
duration_send(PG_FUNCTION_ARGS)
{
	Duration   duration = PG_GETARG_DURATION(0);
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
duration2itm(Duration span, struct pg_itm *itm)
{
	TimeOffset	time;
	TimeOffset	tfrac;

	itm->tm_year = 0;
	itm->tm_mon = 0;
	itm->tm_mday = 0;
	time = span;

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
itmin2duration(struct pg_itm_in *itm_in, Duration *span)
{
	if (itm_in->tm_year != 0 || itm_in->tm_mon != 0 || itm_in->tm_mday != 0)
		return -1;
	*span = itm_in->tm_usec;
	return 0;
}
