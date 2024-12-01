CREATE EXTENSION pg_duration;

-- Valid duration input

SELECT duration '42 hour';
SELECT duration '43 hours';
SELECT duration '44 h';
SELECT duration '45 minute';
SELECT duration '46 minutes';
SELECT duration '47 m';
SELECT duration '48 second';
SELECT duration '49 seconds';
SELECT duration '50 s';
SELECT duration '51 millisecond';
SELECT duration '52 milliseconds';
SELECT duration '53 ms';
SELECT duration '54 microsecond';
SELECT duration '55 microseconds';
SELECT duration '56 us';
SELECT duration '-42 hour';
SELECT duration '-43 hours';
SELECT duration '-44 h';
SELECT duration '-45 minute';
SELECT duration '-46 minutes';
SELECT duration '-47 m';
SELECT duration '-48 second';
SELECT duration '-49 seconds';
SELECT duration '-50 s';
SELECT duration '-51 millisecond';
SELECT duration '-52 milliseconds';
SELECT duration '-53 ms';
SELECT duration '-54 microsecond';
SELECT duration '-55 microseconds';
SELECT duration '-56 us';
SELECT duration '1 minute 2 h 3 microseconds 4 second 5 ms';
SELECT duration '36 minutes ago';

SELECT duration '20:13:41';
SELECT duration 'PT20:13:41';

-- Invalid duration input

SELECT duration '100 millennium';
SELECT duration '101 millenniums';
SELECT duration '102 century';
SELECT duration '103 centuries';
SELECT duration '104 decade';
SELECT duration '105 decades';
SELECT duration '106 year';
SELECT duration '107 years';
SELECT duration '108 y';
SELECT duration '109 month';
SELECT duration '110 months';
SELECT duration '111 week';
SELECT duration '112 weeks';
SELECT duration '113 w';
SELECT duration '114 day';
SELECT duration '115 days';
SELECT duration '116 d';
SELECT duration '5 seconds 2 days';

SELECT duration 'P1995-08-06T20:13:41';

-- Comparison

SELECT duration '1 sec' < duration '1 hour';
SELECT duration '1 millisecond' < duration '1 ms';
SELECT duration '1 minute' < duration '1 us';
SELECT duration '1 sec' <= duration '1 hour';
SELECT duration '1 millisecond' <= duration '1 ms';
SELECT duration '1 minute' <= duration '1 us';
SELECT duration '1 sec' > duration '1 hour';
SELECT duration '1 millisecond' > duration '1 ms';
SELECT duration '1 minute' > duration '1 us';
SELECT duration '1 sec' >= duration '1 hour';
SELECT duration '1 millisecond' >= duration '1 ms';
SELECT duration '1 minute' >= duration '1 us';
SELECT duration '1 sec' = duration '1 hour';
SELECT duration '1 millisecond' = duration '1 ms';
SELECT duration '1 minute' = duration '1 us';
SELECT duration '1 sec' <> duration '1 hour';
SELECT duration '1 millisecond' <> duration '1 ms';
SELECT duration '1 minute' <> duration '1 us';

-- Arithmetic
SELECT - duration '10 minutes';
SELECT duration '55 seconds' + duration '12 hours';
SELECT duration '2 hours' - duration '30 minutes';
SELECT duration '42 minutes' * 10.5;
SELECT duration '42 minutes' * 0.0;
SELECT duration '5 hours 40 minutes 30 s' / 3.7;

SELECT - duration '-9223372036854775807 us';
SELECT duration '9223372036854775806 us' + duration '1 us';
SELECT duration '9223372036854775806 us' + duration '2 us';
SELECT duration '-9223372036854775807 us' - duration '1 us';
SELECT duration '-9223372036854775807 us' - duration '2 us';
SELECT duration '4611686018427387903 us' * 2.5;
SELECT duration '4611686018427387903 us' * 'nan'::float8;
SELECT duration '4611686018427387903 us' * 'infinity'::float8;
SELECT duration '4611686018427387903 us' * '-infinity'::float8;
SELECT duration '0 us' * 'infinity'::float8;
SELECT duration '0 us' * '-infinity'::float8;
SELECT duration '-4611686018427387904 us' / 0.5;
SELECT duration '4611686018427387904 us' / 0.0;
SELECT duration '4611686018427387904 us' / 'nan'::float8;
SELECT duration '4611686018427387903 us' / 'infinity'::float8;
SELECT duration '4611686018427387903 us' / '-infinity'::float8;

-- Infinity
SELECT duration 'infinity';
SELECT duration '-infinity';

SELECT duration 'infinity' > duration '999 hours';
SELECT duration 'infinity' >= duration '999 hours';
SELECT duration 'infinity' < duration '999 hours';
SELECT duration 'infinity' <= duration '999 hours';
SELECT duration 'infinity' = duration '999 hours';
SELECT duration 'infinity' <> duration '999 hours';

SELECT duration '-infinity' > duration '999 hours';
SELECT duration '-infinity' >= duration '999 hours';
SELECT duration '-infinity' < duration '999 hours';
SELECT duration '-infinity' <= duration '999 hours';
SELECT duration '-infinity' = duration '999 hours';
SELECT duration '-infinity' <> duration '999 hours';

SELECT duration 'infinity' > duration 'infinity';
SELECT duration 'infinity' >= duration 'infinity';
SELECT duration 'infinity' < duration 'infinity';
SELECT duration 'infinity' <= duration 'infinity';
SELECT duration 'infinity' = duration 'infinity';
SELECT duration 'infinity' <> duration 'infinity';

SELECT duration 'infinity' > duration '-infinity';
SELECT duration 'infinity' >= duration '-infinity';
SELECT duration 'infinity' < duration '-infinity';
SELECT duration 'infinity' <= duration '-infinity';
SELECT duration 'infinity' = duration '-infinity';
SELECT duration 'infinity' <> duration '-infinity';

SELECT duration '-infinity' > duration 'infinity';
SELECT duration '-infinity' >= duration 'infinity';
SELECT duration '-infinity' < duration 'infinity';
SELECT duration '-infinity' <= duration 'infinity';
SELECT duration '-infinity' = duration 'infinity';
SELECT duration '-infinity' <> duration 'infinity';

SELECT duration '-infinity' > duration '-infinity';
SELECT duration '-infinity' >= duration '-infinity';
SELECT duration '-infinity' < duration '-infinity';
SELECT duration '-infinity' <= duration '-infinity';
SELECT duration '-infinity' = duration '-infinity';
SELECT duration '-infinity' <> duration '-infinity';

SELECT - duration 'infinity';
SELECT - duration '-infinity';

SELECT duration 'infinity' + duration '42 ms';
SELECT duration '-infinity' + duration '42 ms';
SELECT duration 'infinity' + duration 'infinity';
SELECT duration 'infinity' + duration '-infinity';
SELECT duration '-infinity' + duration 'infinity';
SELECT duration '-infinity' + duration '-infinity';

SELECT duration 'infinity' - duration '42 ms';
SELECT duration '-infinity' - duration '42 ms';
SELECT duration 'infinity' - duration 'infinity';
SELECT duration 'infinity' - duration '-infinity';
SELECT duration '-infinity' - duration 'infinity';
SELECT duration '-infinity' - duration '-infinity';

SELECT duration 'infinity' * 15.6;
SELECT duration 'infinity' * -15.6;
SELECT duration 'infinity' * 'infinity'::float8;
SELECT duration 'infinity' * '-infinity'::float8;
SELECT duration 'infinity' * 'nan'::float8;
SELECT duration 'infinity' * 0.0;
SELECT duration '-infinity' * 15.6;
SELECT duration '-infinity' * -15.6;
SELECT duration '-infinity' * 'infinity'::float8;
SELECT duration '-infinity' * '-infinity'::float8;
SELECT duration '-infinity' * 'nan'::float8;
SELECT duration '-infinity' * 0.0;

SELECT duration 'infinity' / 32.1;
SELECT duration 'infinity' / -32.1;
SELECT duration 'infinity' / 'infinity'::float8;
SELECT duration 'infinity' / '-infinity'::float8;
SELECT duration 'infinity' / 'nan'::float8;
SELECT duration 'infinity' / 0.0;
SELECT duration '-infinity' / 32.1;
SELECT duration '-infinity' / -32.1;
SELECT duration '-infinity' / 'infinity'::float8;
SELECT duration '-infinity' / '-infinity'::float8;
SELECT duration '-infinity' / 'nan'::float8;
SELECT duration '-infinity' / 0.0;

-- This matches PostgreSQL semantics, but is probably incorrect.
SELECT duration '9223372036854775807 us';
SELECT duration '-9223372036854775808 us';

-- Inserts and indexes
DROP SCHEMA IF EXISTS regress CASCADE;
CREATE SCHEMA regress;
CREATE TABLE regress.t (d1 duration, d2 duration);
CREATE INDEX idx1 ON regress.t USING BTREE (d1);
CREATE INDEX idx2 ON regress.t USING HASH (d2);
INSERT INTO regress.t VALUES ('1 s 6 m', '5 us'), ('500ms 4 h', '42 seconds 3 us'), ('666 hours', '999 min');
SELECT * FROM regress.t;
SELECT d1 FROM regress.t WHERE d1 > '1 hour';
SELECT d2 FROM regress.t WHERE d2 = '42 seconds 3 microseconds';
DROP SCHEMA regress CASCADE;
