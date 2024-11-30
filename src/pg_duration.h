/* -------------------------------------------------------------------------
 *
 * pg_duration.h
 *
 * -------------------------------------------------------------------------
 */

#include "postgres.h"

#include "utils/datetime.h"

typedef TimeOffset Duration;

static inline Duration
DatumGetDuration(Datum X)
{
	return (Duration) DatumGetInt64(X);
}

static inline Datum
DurationGetDatum(const Duration X)
{
	return Int64GetDatum(X);
}

#define PG_GETARG_DURATION(n) DatumGetDuration(PG_GETARG_DATUM(n))
#define PG_RETURN_DURATION(x) return DurationGetDatum(x)

void		duration2itm(Duration span, struct pg_itm *itm);
int			itmin2duration(struct pg_itm_in *itm_in, Duration * span);

/*
 * We reserve the minumum and maximum int64 value to represent
 * duration -infinity and +infinity.
 */
#define DURATION_NOBEGIN(d)	\
	do {(d) = PG_INT64_MIN;} while (0)

#define DURATION_IS_NOBEGIN(d) ((d) == PG_INT64_MIN)

#define DURATION_NOEND(d)		\
	do {(d) = PG_INT64_MAX;} while (0)

#define DURATION_IS_NOEND(d) ((d) == PG_INT64_MAX)

#define DURATION_NOT_FINITE(d) (DURATION_IS_NOBEGIN(d) || DURATION_IS_NOEND(d))
