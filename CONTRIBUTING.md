# Contributing

## Testing

To execute all tests run:

```bash
make
make install
mask installcheck
```

You must have a running PostgreSQL server and the default user must have `LOGIN` and `SUPERUSER` privileges.

## Design

`duration` should behave exactly like an `interval` whose `month` and `day` fields are always 0. The implementation of
the `duration` type in C is a single 64-bit integer to represent microseconds. When possible we wrap existing `interval`
functions. This causes some weird behavior like including the word `interval` in error messages instead of `duration`, or
accepting some input/output formats that don't make sense for `duration`s.
