/* contrib/pg_duration/pg_duration--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_duration" to load this file. \quit

-- Create the user-defined type for durations (duration)

CREATE TYPE duration;

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

CREATE TYPE duration (
    INTERNALLENGTH = 8,
    INPUT = duration_in,
    OUTPUT = duration_out,
    RECEIVE = duration_recv,
    SEND = duration_send,
    ALIGNMENT = int4
);

COMMENT ON TYPE duration IS 'duration of time';