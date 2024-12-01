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

-- Functions helper table
CREATE TEMP TABLE valid_fields(f text);
INSERT
INTO
	valid_fields
VALUES
	('hour'),
	('minute'),
	('second'),
	('millisecond'),
	('microsecond');
CREATE TEMPORARY TABLE func_table (d duration);
INSERT
INTO
	func_table
VALUES
	(duration '1 hour 2 minutes 3 seconds 4 milliseconds 5 microseconds'),
	(-duration '1 hour 2 minutes 3 seconds 4 milliseconds 5 microseconds');

-- make_duration

SELECT make_duration();
SELECT make_duration(1);
SELECT make_duration(1, 2);
SELECT make_duration(1, 2, 3.456);

SELECT make_duration(2147483647, 2147483647, 9223372036854775807);

-- isfinite

SELECT isfinite(duration '112 hours');
SELECT isfinite(duration 'infinity');
SELECT isfinite(duration '-infinity');

-- date_trunc

SELECT f, d, date_trunc(f, d) FROM valid_fields, func_table;
SELECT date_trunc('epoch', d) FROM func_table;
SELECT date_trunc('millennium', d) FROM func_table;
SELECT date_trunc('century', d) FROM func_table;
SELECT date_trunc('decade', d) FROM func_table;
SELECT date_trunc('year', d) FROM func_table;
SELECT date_trunc('quarter', d) FROM func_table;
SELECT date_trunc('month', d) FROM func_table;
SELECT date_trunc('week', d) FROM func_table;
SELECT date_trunc('day', d) FROM func_table;

-- date_part

SELECT f, d, date_part(f, d) FROM valid_fields, func_table;
SELECT date_part('epoch', d) FROM func_table;
SELECT date_part('millennium', d) FROM func_table;
SELECT date_part('century', d) FROM func_table;
SELECT date_part('decade', d) FROM func_table;
SELECT date_part('year', d) FROM func_table;
SELECT date_part('quarter', d) FROM func_table;
SELECT date_part('month', d) FROM func_table;
SELECT date_part('week', d) FROM func_table;
SELECT date_part('day', d) FROM func_table;

-- extract_duration

SELECT f, d, extract_duration(f, d) FROM valid_fields, func_table;
SELECT extract_duration('epoch', d) FROM func_table;
SELECT extract_duration('millennium', d) FROM func_table;
SELECT extract_duration('century', d) FROM func_table;
SELECT extract_duration('decade', d) FROM func_table;
SELECT extract_duration('year', d) FROM func_table;
SELECT extract_duration('quarter', d) FROM func_table;
SELECT extract_duration('month', d) FROM func_table;
SELECT extract_duration('week', d) FROM func_table;
SELECT extract_duration('day', d) FROM func_table;

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
	inf_table AS t1, inf_table AS t2
WHERE
	NOT isfinite(t1.d) OR NOT isfinite(t2.d);
-- Negation
SELECT d, -d FROM inf_table WHERE NOT isfinite(d);
-- Addition
SELECT duration 'infinity' + duration '42 ms';
SELECT duration '-infinity' + duration '42 ms';
SELECT duration 'infinity' + duration 'infinity';
SELECT duration 'infinity' + duration '-infinity';
SELECT duration '-infinity' + duration 'infinity';
SELECT duration '-infinity' + duration '-infinity';
-- Subtraction
SELECT duration 'infinity' - duration '42 ms';
SELECT duration '-infinity' - duration '42 ms';
SELECT duration 'infinity' - duration 'infinity';
SELECT duration 'infinity' - duration '-infinity';
SELECT duration '-infinity' - duration 'infinity';
SELECT duration '-infinity' - duration '-infinity';
-- Multiplication
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
-- Division
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
-- date_trunc
SELECT f, d, date_trunc(f, d) FROM valid_fields, inf_table WHERE NOT isfinite(d);
SELECT date_trunc('epoch', duration 'infinity');
SELECT date_trunc('millennium', duration 'infinity');
SELECT date_trunc('century', duration 'infinity');
SELECT date_trunc('decade', duration 'infinity');
SELECT date_trunc('year', duration 'infinity');
SELECT date_trunc('quarter', duration 'infinity');
SELECT date_trunc('month', duration 'infinity');
SELECT date_trunc('week', duration 'infinity');
SELECT date_trunc('day', duration 'infinity');
SELECT date_trunc('epoch', duration '-infinity');
SELECT date_trunc('millennium', duration '-infinity');
SELECT date_trunc('century', duration '-infinity');
SELECT date_trunc('decade', duration '-infinity');
SELECT date_trunc('year', duration '-infinity');
SELECT date_trunc('quarter', duration '-infinity');
SELECT date_trunc('month', duration '-infinity');
SELECT date_trunc('week', duration '-infinity');
SELECT date_trunc('day', duration '-infinity');
-- date_part
SELECT f, d, date_part(f, d) FROM valid_fields, inf_table WHERE NOT isfinite(d);
SELECT date_part('epoch', duration 'infinity');
SELECT date_part('millennium', duration 'infinity');
SELECT date_part('century', duration 'infinity');
SELECT date_part('decade', duration 'infinity');
SELECT date_part('year', duration 'infinity');
SELECT date_part('quarter', duration 'infinity');
SELECT date_part('month', duration 'infinity');
SELECT date_part('week', duration 'infinity');
SELECT date_part('day', duration 'infinity');
SELECT date_part('epoch', duration '-infinity');
SELECT date_part('millennium', duration '-infinity');
SELECT date_part('century', duration '-infinity');
SELECT date_part('decade', duration '-infinity');
SELECT date_part('year', duration '-infinity');
SELECT date_part('quarter', duration '-infinity');
SELECT date_part('month', duration '-infinity');
SELECT date_part('week', duration '-infinity');
SELECT date_part('day', duration '-infinity');
-- extract_duration
SELECT f, d, extract_duration(f, d) FROM valid_fields, inf_table WHERE NOT isfinite(d);
SELECT extract_duration('epoch', duration 'infinity');
SELECT extract_duration('millennium', duration 'infinity');
SELECT extract_duration('century', duration 'infinity');
SELECT extract_duration('decade', duration 'infinity');
SELECT extract_duration('year', duration 'infinity');
SELECT extract_duration('quarter', duration 'infinity');
SELECT extract_duration('month', duration 'infinity');
SELECT extract_duration('week', duration 'infinity');
SELECT extract_duration('day', duration 'infinity');
SELECT extract_duration('epoch', duration '-infinity');
SELECT extract_duration('millennium', duration '-infinity');
SELECT extract_duration('century', duration '-infinity');
SELECT extract_duration('decade', duration '-infinity');
SELECT extract_duration('year', duration '-infinity');
SELECT extract_duration('quarter', duration '-infinity');
SELECT extract_duration('month', duration '-infinity');
SELECT extract_duration('week', duration '-infinity');
SELECT extract_duration('day', duration '-infinity');
-- Overflow
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
