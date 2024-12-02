# pg_duration

[![PGXN version](https://badge.fury.io/pg/pg_duration.svg)](https://badge.fury.io/pg/pg_duration)
[![Build Status](https://github.com/jkosh44/pg_duration/workflows/CI/badge.svg)](https://github.com/jkosh44/pg_duration/actions)

pg_duration is a PostgreSQL extension that adds a `duration` data type to PostgreSQL. `duration` allows users to store
the total time of some event in their databases. `duration` is very similar to the builtin
[`interval`](https://www.postgresql.org/docs/17/datatype-datetime.html) type, except `duration` does not have a months
or days component, only a microsecond component.

`pg_duration` is compatible with PostgreSQL versions 17 and above.

## Installation

Before beginning, make sure that the PostgreSQL server dev libraries are downloaded to your
machine: https://www.postgresql.org/download.

First build pg_duration:

```bash
make
make install
```

Note: You may need to run `make install` under `sudo`.

Then conntect to a database as a superuser and run:

```SQL
CREATE EXTENSION pg_duration;
```

## Usage

### Input

All valid [`interval` input](https://www.postgresql.org/docs/current/datatype-datetime.html#DATATYPE-INTERVAL-INPUT)
that doesn't specify units larger than hours, is valid `duration` input.

### Output

`duration` output is the same as
[`interval` output](https://www.postgresql.org/docs/current/datatype-datetime.html#DATATYPE-INTERVAL-OUTPUT), without
units larger than hours.

### Operators

| Operator                            | Description           | Example                                                |
|-------------------------------------|-----------------------|--------------------------------------------------------|
| `duration + duration` -> `duration` | Add durations         | `duration '5 sec' + duration '10 min'` -> `00:10:05`   |
| `duration - duration` -> `duration` | Subtract durations    | `duration '6 hours' - duration '15 min'` -> `05:45:00` |
| `- duration` -> `duration`          | Negate a duration     | `- duration '450 milliseconds'` -> `-00:00:00.45`      |
| `duration * float8` -> `duration`   | Multiply a duration   | `duration '3 hours' * 2.5` -> `07:30:00`               |
| `duration / float8` -> `duration`   | Divide a duration     | `duration '3 hours' / 2.5` -> `01:12:00`               |
| `duration < duration` -> `boolean`  | Less than             | `duration '10 min' < duration '1 hour'` -> `t`         |
| `duration <= duration` -> `boolean` | Less than or equal    | `duration '10 min' <= duration '1 hour'` -> `t`        |
| `duration > duration` -> `boolean`  | Greater than          | `duration '10 min' > duration '1 hour'` -> `f`         |
| `duration >= duration` -> `boolean` | Greater than or equal | `duration '10 min' >= duration '1 hour'` -> `f`        |
| `duration = duration` -> `boolean`  | Equal                 | `duration '10 min' = duration '1 hour'` -> `f`         |
| `duration <> duration` -> `boolean` | Not equal             | `duration '10 min' <> duration '1 hour'` -> `t`        |

### Functions

| Function                                                                           | Description                                                                                | Example                                                                             |
|------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| `make_duration([hours int [, mins int [, secs double precision ]]])` -> `duration` | Create duration from hours, minutes, and seconds fields, each of which can default to zero | `make_duration(12)` -> `12:00:00`                                                   |
| `isfinite(duration)` -> `boolean`                                                  | Test for finite duration (not +/-infinity)                                                 | `isfinite(duration '1 hour')` -> `true`                                             |
| `date_trunc(text, duration)` -> `duration`                                         | Truncate to specified precision; see [date_trunc][date_trunc]                              | `date_trunc('second', duration '3 hours 40 minutes 5 seconds 60 ms')` -> `03:40:05` |
| `date_part(text, duration)` -> `double precision`                                  | Get duration subfield (equivalent to `extract_duration`); see [date_part][date_part]       | `date_part('minute', duration '1 hour 2 minutes 3 seconds')` -> `2`                 |
| `extract_duration(text, duration)` -> `numeric`                                    | Get duration subfield; see [extract][date_part]                                            | `extract_duration('second', duration '1 hour 2 minutes 3 seconds')` -> `3.004`      |

### Casts

| Source Type | Target Type | Cast Type |
|-------------|-------------|-----------|
| `duration`  | `interval`  | implicit  |
| `interval`  | `duration`  | explicit  |

### Aggregates

| Aggregate | Return Type | Description                                                |
|-----------|-------------|------------------------------------------------------------|
| `avg`     | `duration`  | The average (arithmetic mean) of all non-null input values |
| `count`   | `bigint`    | Number of input rows for which the value is not null       |
| `max`     | `duration`  | Maximum value across all non-null input values             |
| `min`     | `duration`  | Minimum value across all non-null input values             |
| `sum`     | `duration`  | Sum across all non-null input values                       |

### Supported Indexes

The `duration` type supports the following indexes

- `BTREE`
- `HASH`

## Rationale

Why not just use the `interval` type? For starters, the `interval` type is 16 bytes while the `duration` type is only 8
bytes. More importantly, `interval`s only tell us the time between two events, not the absolute time of some event. For
example, how many hours is `Interval '2 months 15 days'`? To answer that you'd need to know if the months had 28, 29,
30, or 31 days and if the days had 23, 24, or 25 hours. `duration`s on the other hand can always be compared to other
`duration`s and return a meaningful answer.

[date_trunc]: https://www.postgresql.org/docs/17/functions-datetime.html#FUNCTIONS-DATETIME-TRUNC
[date_part]: https://www.postgresql.org/docs/17/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT