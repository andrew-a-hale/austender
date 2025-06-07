duckdb dat.db -c "create table if not exists jobs (
  job_id datetime primary key
  , attempts int
  , processed_at datetime
  , completed_at datetime
  , last_error_msg varchar
);"

duckdb dat.db -c "insert into jobs
select
  today() + generate_series::int as job_id
  , 0 as attempts
  , null::datetime as processed_at
  , null::datetime as completed_at
  , null::varchar as last_error_msg
from generate_series(date '2013-01-01' - today(), 0)
on conflict do nothing;"

duckdb dat.db -c "create table if not exists dlq (
  job_id datetime
  , attempts int
  , processed_at datetime
  , last_error_msg varchar
);"
