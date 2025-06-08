duckdb dat.db -c "\
install ducklake;
attach 'ducklake:metadata.ducklake' as lake (DATA_PATH 'datalake/');

create table if not exists jobs (
  job_id date primary key
  , attempts int
  , processed_at datetime
  , completed_at datetime
  , last_error_msg varchar
);

insert into jobs
select
  today() + generate_series::int as job_id
  , 0 as attempts
  , null::datetime as processed_at
  , null::datetime as completed_at
  , null::varchar as last_error_msg
from generate_series(date '2025-06-01' - today(), 0)
on conflict do nothing;

create table if not exists dlq (
  job_id date primary key
  , attempts int
  , processed_at datetime
  , last_error_msg varchar
);

create table if not exists lake.raw_tenders (
  uri varchar
  , publisher_name varchar
  , published_date datetime
  , license varchar
  , version varchar
  , releases $(cat releases_schema_duckdb.txt)
  , extensions varchar[]
  , links json
);"
