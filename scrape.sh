#!/bin/bash
set -e

ARCHIVE=archive/
export TYPE=contractStart
export RAW=datalake/bronze
export LOG=$(date "+%Y%m%d%H%M%S%3N").log
[ -d $ARCHIVE ] || mkdir -p $ARCHIVE
[ -d $RAW ] || mkdir -p $RAW
[ -e $LOG ] || touch $LOG

function call() {
  start="$1"T00:00:00Z
  end="$1"T23:59:59Z

  out=$RAW/$(date -I -d "$start")
  [ -d $out ] || mkdir $out

  payload=$(curl -s "https://api.tenders.gov.au/ocds/findByDates/$TYPE/$start/$end")

  err=$(echo $payload | jq -r '.errorCode // empty')
  if [ -z $err ]; then
    jq -n -c --arg job $1 '{"level": "SUCCESS", "job_id": $job}' | tee -a $LOG
    echo $payload >$out/data.json
  else
    echo $payload |
      jq -c --arg job $1 '{"level": "ERROR", "job_id": $job, "msg": .message}' |
      tee -a $LOG
  fi
}

export -f call

# Job Queue
# job_id is the date
jobs=$(duckdb dat.db -list -noheader -c "select job_id from jobs where completed_at is null and attempts < 3")
[ $(wc -w <<<$jobs) -eq 0 ] && rm $LOG && exit 0

# EXTRACT
TICK=$(date +%s%N)
parallel call ::: $jobs
TOCK=$(date +%s%N)
ELAPSED=$((TOCK - TICK))
REQUESTS=$(wc -l <$LOG)
MS=$((ELAPSED / 1000000))
echo "SCRAPE -- Elapsed time: $MS ms"
echo "SCRAPE -- RPS: $((REQUESTS * 1000 / $MS))"

# Update Job Queue
cat $LOG |
  jq -c -r 'select(.level == "SUCCESS")' |
  duckdb dat.db -c "\
  update jobs
  set attempts = attempts + 1, processed_at = now(), completed_at = now()
  from read_json('/dev/stdin', columns = {job_id: 'datetime'}) as i
  where jobs.job_id = i.job_id"

cat $LOG |
  jq -c -r 'select(.level == "ERROR")' |
  duckdb dat.db -c "\
  update jobs
  set attempts = attempts + 1, processed_at = now(), last_error_msg = msg
  from read_json('/dev/stdin', columns = {job_id: 'datetime', msg: 'varchar'}) as i
  where jobs.job_id = i.job_id"

duckdb dat.db -c "\
  insert into dlq (job_id, attempts, processed_at, last_error_msg)
  select job_id, attempts, processed_at, last_error_msg
  from jobs
  where attempts > 2;

  delete from jobs where attempts > 2;"

# LOAD
TICK=$(date +%s%N)
duckdb -c "copy (from '$RAW/**/*.json') to 'tenders.parquet'"
TOCK=$(date +%s%N)
ELAPSED=$((TOCK - TICK))
echo "LOAD -- Elapsed time: $((ELAPSED / 1000000)) ms"

# Clean Up
mv $LOG archive/$LOG
