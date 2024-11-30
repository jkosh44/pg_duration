CREATE EXTENSION pg_duration;

-- Valid duration input

SELECT DURATION '42 hour';
SELECT DURATION '43 hours';
SELECT DURATION '44 h';
SELECT DURATION '45 minute';
SELECT DURATION '46 minutes';
SELECT DURATION '47 m';
SELECT DURATION '48 second';
SELECT DURATION '49 seconds';
SELECT DURATION '50 s';
SELECT DURATION '51 millisecond';
SELECT DURATION '52 milliseconds';
SELECT DURATION '53 ms';
SELECT DURATION '54 microsecond';
SELECT DURATION '55 microseconds';
SELECT DURATION '56 us';
SELECT DURATION '-42 hour';
SELECT DURATION '-43 hours';
SELECT DURATION '-44 h';
SELECT DURATION '-45 minute';
SELECT DURATION '-46 minutes';
SELECT DURATION '-47 m';
SELECT DURATION '-48 second';
SELECT DURATION '-49 seconds';
SELECT DURATION '-50 s';
SELECT DURATION '-51 millisecond';
SELECT DURATION '-52 milliseconds';
SELECT DURATION '-53 ms';
SELECT DURATION '-54 microsecond';
SELECT DURATION '-55 microseconds';
SELECT DURATION '-56 us';
SELECT DURATION '1 minute 2 h 3 microseconds 4 second 5 ms';
SELECT DURATION '36 minutes ago';

SELECT DURATION '20:13:41';
SELECT DURATION 'PT20:13:41';

-- Invalid duration input

SELECT DURATION '100 millennium';
SELECT DURATION '101 millenniums';
SELECT DURATION '102 century';
SELECT DURATION '103 centuries';
SELECT DURATION '104 decade';
SELECT DURATION '105 decades';
SELECT DURATION '106 year';
SELECT DURATION '107 years';
SELECT DURATION '108 y';
SELECT DURATION '109 month';
SELECT DURATION '110 months';
SELECT DURATION '111 week';
SELECT DURATION '112 weeks';
SELECT DURATION '113 w';
SELECT DURATION '114 day';
SELECT DURATION '115 days';
SELECT DURATION '116 d';
SELECT DURATION '5 seconds 2 days';

SELECT DURATION 'P1995-08-06T20:13:41';

-- Comparison

SELECT DURATION '1 sec' < DURATION '1 hour';
SELECT DURATION '1 millisecond' < DURATION '1 ms';
SELECT DURATION '1 minute' < DURATION '1 us';
SELECT DURATION '1 sec' <= DURATION '1 hour';
SELECT DURATION '1 millisecond' <= DURATION '1 ms';
SELECT DURATION '1 minute' <= DURATION '1 us';
SELECT DURATION '1 sec' > DURATION '1 hour';
SELECT DURATION '1 millisecond' > DURATION '1 ms';
SELECT DURATION '1 minute' > DURATION '1 us';
SELECT DURATION '1 sec' >= DURATION '1 hour';
SELECT DURATION '1 millisecond' >= DURATION '1 ms';
SELECT DURATION '1 minute' >= DURATION '1 us';
SELECT DURATION '1 sec' = DURATION '1 hour';
SELECT DURATION '1 millisecond' = DURATION '1 ms';
SELECT DURATION '1 minute' = DURATION '1 us';
SELECT DURATION '1 sec' <> DURATION '1 hour';
SELECT DURATION '1 millisecond' <> DURATION '1 ms';
SELECT DURATION '1 minute' <> DURATION '1 us';

-- Arithmetic
SELECT - DURATION '10 minutes';
SELECT DURATION '55 seconds' + DURATION '12 hours';
SELECT DURATION '2 hours' - DURATION '30 minutes';

SELECT - DURATION '-9223372036854775807 us';
SELECT DURATION '9223372036854775806 us' + DURATION '1 us';
SELECT DURATION '9223372036854775806 us' + DURATION '2 us';
SELECT DURATION '-9223372036854775807 us' - DURATION '1 us';
SELECT DURATION '-9223372036854775807 us' - DURATION '2 us';

-- Infinity
SELECT DURATION 'infinity';
SELECT DURATION '-infinity';

SELECT - DURATION 'infinity';
SELECT - DURATION '-infinity';

SELECT DURATION 'infinity' + DURATION '42 ms';
SELECT DURATION '-infinity' + DURATION '42 ms';
SELECT DURATION 'infinity' + DURATION 'infinity';
SELECT DURATION 'infinity' + DURATION '-infinity';
SELECT DURATION '-infinity' + DURATION 'infinity';
SELECT DURATION '-infinity' + DURATION '-infinity';

SELECT DURATION 'infinity' - DURATION '42 ms';
SELECT DURATION '-infinity' - DURATION '42 ms';
SELECT DURATION 'infinity' - DURATION 'infinity';
SELECT DURATION 'infinity' - DURATION '-infinity';
SELECT DURATION '-infinity' - DURATION 'infinity';
SELECT DURATION '-infinity' - DURATION '-infinity';

SELECT DURATION 'infinity' > DURATION '999 hours';
SELECT DURATION 'infinity' >= DURATION '999 hours';
SELECT DURATION 'infinity' < DURATION '999 hours';
SELECT DURATION 'infinity' <= DURATION '999 hours';
SELECT DURATION 'infinity' = DURATION '999 hours';
SELECT DURATION 'infinity' <> DURATION '999 hours';

SELECT DURATION '-infinity' > DURATION '999 hours';
SELECT DURATION '-infinity' >= DURATION '999 hours';
SELECT DURATION '-infinity' < DURATION '999 hours';
SELECT DURATION '-infinity' <= DURATION '999 hours';
SELECT DURATION '-infinity' = DURATION '999 hours';
SELECT DURATION '-infinity' <> DURATION '999 hours';

SELECT DURATION 'infinity' > DURATION 'infinity';
SELECT DURATION 'infinity' >= DURATION 'infinity';
SELECT DURATION 'infinity' < DURATION 'infinity';
SELECT DURATION 'infinity' <= DURATION 'infinity';
SELECT DURATION 'infinity' = DURATION 'infinity';
SELECT DURATION 'infinity' <> DURATION 'infinity';

SELECT DURATION 'infinity' > DURATION '-infinity';
SELECT DURATION 'infinity' >= DURATION '-infinity';
SELECT DURATION 'infinity' < DURATION '-infinity';
SELECT DURATION 'infinity' <= DURATION '-infinity';
SELECT DURATION 'infinity' = DURATION '-infinity';
SELECT DURATION 'infinity' <> DURATION '-infinity';

SELECT DURATION '-infinity' > DURATION 'infinity';
SELECT DURATION '-infinity' >= DURATION 'infinity';
SELECT DURATION '-infinity' < DURATION 'infinity';
SELECT DURATION '-infinity' <= DURATION 'infinity';
SELECT DURATION '-infinity' = DURATION 'infinity';
SELECT DURATION '-infinity' <> DURATION 'infinity';

SELECT DURATION '-infinity' > DURATION '-infinity';
SELECT DURATION '-infinity' >= DURATION '-infinity';
SELECT DURATION '-infinity' < DURATION '-infinity';
SELECT DURATION '-infinity' <= DURATION '-infinity';
SELECT DURATION '-infinity' = DURATION '-infinity';
SELECT DURATION '-infinity' <> DURATION '-infinity';

-- This matches PostgreSQL semantics, but is probably incorrect.
SELECT DURATION '9223372036854775807 us';
SELECT DURATION '-9223372036854775808 us';

-- Inserts and indexes
DROP SCHEMA IF EXISTS regress CASCADE;
CREATE SCHEMA regress;
CREATE TABLE regress.t (d1 DURATION, d2 DURATION);
CREATE INDEX idx1 ON regress.t USING BTREE (d1);
CREATE INDEX idx2 ON regress.t USING HASH (d2);
INSERT INTO regress.t VALUES ('1 s 6 m', '5 us'), ('500ms 4 h', '42 seconds 3 us'), ('666 hours', '999 min');
SELECT * FROM regress.t;
SELECT d1 FROM regress.t WHERE d1 > '1 hour';
SELECT d2 FROM regress.t WHERE d2 = '42 seconds 3 microseconds';
DROP SCHEMA regress CASCADE;
