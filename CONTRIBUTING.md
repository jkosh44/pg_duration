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
accepting some input/output formats that don't make sense for `duration`s. If we're not wrapping `interval` functions, we
should model our implementations after the existing `interval` implementations.

## Debugging

When debugging the extension I have found it much easier to install the extension into a PostgreSQL server built from
source with debug symbols. The process I have used on a Linux machine is specified below. I am aware that it is probably
extremely hacky, but it works for me and I haven't found a better way. If someone knows a better process, then please
open a PR and update these steps.

```bash
PG_DIR=/path/to/postgres/source/code
DUR_DIR=/path/to/pg_duration/source/code
TARGET=/path/to/postgres/build/directory

# Copy the extension into the postgres contrib directory.
rsync -av --exclude '.git' $DUR_DIR $PG_DIR/contrib

# Build postgres from source.
cd $PG_DIR
make clean && make && make install

# Build the extension using the same version as the postgres source code. We have to slightly modify the Makefile.
cd contrib/pg_duration
head -n -4 Makefile > tmp && mv tmp Makefile
echo 'subdir = contrib/pg_duration' >> Makefile
echo 'top_builddir = ../..' >> Makefile
echo 'include $(top_builddir)/src/Makefile.global' >> Makefile
echo 'include $(top_srcdir)/contrib/contrib-global.mk' >> Makefile
make && sudo make install

# Copy the extension artifacts into the postgres build directory.
cp pg_duration.control $TARGET/share/extension/
cp data/pg_duration--1.0.sql $TARGET/share/extension/
cp src/pg_duration.so $TARGET/lib/
```

Then start PostgreSQL normally (see https://www.postgresql.org/docs/17/install-make.html#INSTALL-SHORT-MAKE), and run

```SQL
CREATE EXTENSION pg_duration;
```

At this point you can use GDB or print line debugging to debug the `pg_duration` extension like you would for normal
PostgreSQL functionality.
