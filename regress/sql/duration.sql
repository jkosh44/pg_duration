CREATE EXTENSION pg_duration;

-- Valid duration input
CREATE TEMP TABLE input_table (s text);
INSERT
INTO
	input_table
VALUES
	('42 hour'),
	('43 hours'),
	('44 h'),
	('45 minute'),
	('46 minutes'),
	('47 m'),
	('48 second'),
	('49 seconds'),
	('50 s'),
	('51 millisecond'),
	('52 milliseconds'),
	('53 ms'),
	('54 microsecond'),
	('55 microseconds'),
	('56 us');
SELECT s, s::duration, ('-' || s)::duration FROM input_table;
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

CREATE TEMP TABLE cmp_table(a duration, b duration);

INSERT
INTO
	cmp_table
VALUES
	('1 sec', '1 hour'), ('1 millisecon', '1 ms'), ('1 minute', '1 us');
SELECT
	a,
	b,
	a < b AS lt,
	a <= b AS le,
	a > b AS gt,
	a >= b AS ge,
	a = b AS eq,
	a != b AS ne
FROM
	cmp_table;

-- Arithmetic
-- Valid
SELECT - duration '10 minutes';
SELECT duration '55 seconds' + duration '12 hours';
SELECT duration '2 hours' - duration '30 minutes';
SELECT duration '42 minutes' * 10.5;
SELECT duration '42 minutes' * 0.0;
SELECT duration '5 hours 40 minutes 30 s' / 3.7;
-- Invalid
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

-- Create helper tables
CREATE TEMP TABLE inf_table(d duration);
INSERT
INTO
	inf_table
VALUES
	('infinity'), ('-infinity'), ('999 hours'), ('-999 hours');
-- Input
SELECT duration 'infinity';
SELECT duration '-infinity';
-- Comparison
SELECT
	t1.d AS a,
	t2.d AS b,
	t1.d < t2.d AS lt,
	t1.d <= t2.d AS le,
	t1.d > t2.d AS gt,
	t1.d >= t2.d AS ge,
	t1.d = t2.d AS eq,
	t1.d != t2.d AS ne
FROM
	inf_table AS t1, inf_table AS t2;
-- Negation
SELECT d, -d FROM inf_table;
-- Arithmetic
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
