# Contributing

## Testing

To execute all tests run:

```bash
make
make install
make installcheck
```

You must have a running PostgreSQL server and the default user must have `LOGIN` and `SUPERUSER` privileges.

## Design

`duration` should behave exactly like an `interval` whose `month` and `day` fields are always 0. The implementation of
the `duration` type in C is a single 64-bit integer to represent microseconds. When possible we wrap existing `interval`
functions. This causes some weird behavior like including the word `interval` in error messages instead of `duration`, or
accepting some input/output formats that don't make sense for `duration`s. If we're not wrapping `interval` functions, we
should model our implementations after the existing `interval` implementations.

We could have been more aggressive in converting durations to intervals, calling the interval function, and converting
back to durations instead of re-implementing functionality. However, we would have to allocate an extra 128 bits for
each duration which would add necessary overhead.

## Releases

To create a new release of `pg_duration`, follow the instructions below:

1. Update the version numbers in `META.json` (two places) and `pg_duration.control`.
2. Run `make dist` which will produce a `pg_duration-x.y.z.zip` archive.
3. Upload the zip file at [pgxn](https://manager.pgxn.org/upload).

See the [how-to](https://manager.pgxn.org/howto) guide for more information.