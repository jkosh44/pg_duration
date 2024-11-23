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
