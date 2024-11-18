MODULES = src/pg_duration
PGFILEDESC = "pg_duration - duration data type"
EXTENSION = pg_duration
DATA = sql/pg_duration--1.0.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
