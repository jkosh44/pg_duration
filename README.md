# pg_duration

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
| `duration < duration` -> `bool`     | Less than             | `duration '10 min' < duration '1 hour'` -> `t`         |
| `duration <= duration` -> `bool`    | Less than or equal    | `duration '10 min' <= duration '1 hour'` -> `t`        |
| `duration > duration` -> `bool`     | Greater than          | `duration '10 min' > duration '1 hour'` -> `f`         |
| `duration >= duration` -> `bool`    | Greater than or equal | `duration '10 min' >= duration '1 hour'` -> `f`        |
| `duration = duration` -> `bool`     | Equal                 | `duration '10 min' = duration '1 hour'` -> `f`         |
| `duration <> duration` -> `bool`    | Not equal             | `duration '10 min' <> duration '1 hour'` -> `t`        |

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
