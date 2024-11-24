/* contrib/pg_duration/pg_duration--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_duration" to load this file. \quit

-- Create the user-defined type for durations (duration)

CREATE TYPE duration;

-- Input/output methods

CREATE FUNCTION duration_in(cstring)
    RETURNS duration
    AS 'MODULE_PATHNAME'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION duration_out(duration)
    RETURNS cstring
    AS 'MODULE_PATHNAME'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION duration_recv(internal)
   RETURNS duration
   AS 'MODULE_PATHNAME'
   LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION duration_send(duration)
   RETURNS bytea
   AS 'MODULE_PATHNAME'
   LANGUAGE C IMMUTABLE STRICT;

-- Indexing methods

CREATE OR REPLACE FUNCTION duration_cmp(duration, duration)
	RETURNS int4
	AS 'MODULE_PATHNAME'
	LANGUAGE C STRICT IMMUTABLE;

COMMENT ON FUNCTION duration_cmp(duration, duration) IS 'btree comparison function';

CREATE OR REPLACE FUNCTION hash_duration(duration)
	RETURNS int4
	AS 'MODULE_PATHNAME'
	LANGUAGE C STRICT IMMUTABLE;

-- Comparison methods

CREATE FUNCTION duration_lt(duration, duration)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

COMMENT ON FUNCTION duration_lt(duration, duration) IS
'less than';

CREATE FUNCTION duration_le(duration, duration)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

COMMENT ON FUNCTION duration_le(duration, duration) IS
'less than or equal';

CREATE FUNCTION duration_gt(duration, duration)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

COMMENT ON FUNCTION duration_gt(duration, duration) IS
'greater than';

CREATE FUNCTION duration_ge(duration, duration)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

COMMENT ON FUNCTION duration_ge(duration, duration) IS
'greater than or equal';

CREATE FUNCTION duration_eq(duration, duration)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

COMMENT ON FUNCTION duration_eq(duration, duration) IS
'equal';

CREATE FUNCTION duration_ne(duration, duration)
RETURNS bool
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

COMMENT ON FUNCTION duration_ne(duration, duration) IS
'not equal';

-- Arithmetic methods

CREATE FUNCTION duration_um(duration)
RETURNS duration
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

COMMENT ON FUNCTION duration_um(duration) IS
'negate';

CREATE FUNCTION duration_pl(duration, duration)
RETURNS duration
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

COMMENT ON FUNCTION duration_pl(duration, duration) IS
'plus';

CREATE FUNCTION duration_mi(duration, duration)
RETURNS duration
AS 'MODULE_PATHNAME'
LANGUAGE C STRICT IMMUTABLE;

COMMENT ON FUNCTION duration_mi(duration, duration) IS
'minus';


-- Define duration type

CREATE TYPE duration (
    INTERNALLENGTH = 8,
    INPUT = duration_in,
    OUTPUT = duration_out,
    RECEIVE = duration_recv,
    SEND = duration_send,
    PASSEDBYVALUE,
    ALIGNMENT = double
);

COMMENT ON TYPE duration IS 'duration of time';

--
-- OPERATORS
--

CREATE OPERATOR < (
	LEFTARG = duration,
	RIGHTARG = duration,
	PROCEDURE = duration_lt,
	COMMUTATOR = '>',
	NEGATOR = '>=',
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
	LEFTARG = duration,
	RIGHTARG = duration,
	PROCEDURE = duration_le,
	COMMUTATOR = '>=',
	NEGATOR = '>',
	RESTRICT = scalarltsel,
	JOIN = scalarltjoinsel
);

CREATE OPERATOR > (
	LEFTARG = duration,
	RIGHTARG = duration,
	PROCEDURE = duration_gt,
	COMMUTATOR = '<',
	NEGATOR = '<=',
	RESTRICT = scalargtsel,
	JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
	LEFTARG = duration,
	RIGHTARG = duration,
	PROCEDURE = duration_ge,
	COMMUTATOR = '<=',
	NEGATOR = '<',
	RESTRICT = scalargtsel,
	JOIN = scalargtjoinsel
);

CREATE OPERATOR = (
	LEFTARG = duration,
	RIGHTARG = duration,
	PROCEDURE = duration_eq,
	COMMUTATOR = '=',
	NEGATOR = '<>',
	RESTRICT = eqsel,
	JOIN = eqjoinsel,
	MERGES
);

CREATE OPERATOR <> (
	LEFTARG = duration,
	RIGHTARG = duration,
	PROCEDURE = duration_ne,
	COMMUTATOR = '<>',
	NEGATOR = '=',
	RESTRICT = neqsel,
	JOIN = neqjoinsel
);

CREATE OPERATOR - (
	RIGHTARG = duration,
	PROCEDURE = duration_um
);

CREATE OPERATOR + (
	LEFTARG = duration,
	RIGHTARG = duration,
	PROCEDURE = duration_pl,
	COMMUTATOR = '+'
);

CREATE OPERATOR - (
	LEFTARG = duration,
	RIGHTARG = duration,
	PROCEDURE = duration_mi,
	COMMUTATOR = '-'
);

-- Create the operator classes for indexing

CREATE OPERATOR CLASS duration_ops
    DEFAULT FOR TYPE duration USING btree AS
        OPERATOR        1       <,
        OPERATOR        2       <=,
        OPERATOR        3       =,
        OPERATOR        4       >=,
        OPERATOR        5       >,
        FUNCTION        1       duration_cmp(duration, duration);

CREATE OPERATOR CLASS duration_ops
    DEFAULT FOR TYPE duration USING hash AS
    OPERATOR    1   =,
    FUNCTION    1   hash_duration(duration);
