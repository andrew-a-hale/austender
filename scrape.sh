#!/bin/bash
set -e

TYPE=contractStart
ARCHIVE=archive/
RAW=datalake/bronze
LOG=$(date "+%Y%m%d%H%M%S%3N").log
[ -d $ARCHIVE ] || mkdir -p $ARCHIVE
[ -d $RAW ] || mkdir -p $RAW
[ -e $LOG ] || touch $LOG

ERRORCODE=100
function call() {
  start="$1"T00:00:00Z
  end="$1"T23:59:59Z

  out=$RAW/$(date -I -d "$start")
  [ -d $out ] || mkdir $out

  payload=$(curl -s "https://api.tenders.gov.au/ocds/findByDates/$TYPE/$start/$end")

  err=$(echo $payload | jq '.errorCode')
  if [ $err == $ERRORCODE ]; then
    msg=$(echo $payload | jq '.message')
    printf "WARNING: NO DATA FOUND FOR $1: $msg\n" | tee -a $LOG
  else
    printf "INFO: FOUND DATA FOR $1\n" | tee -a $LOG
    echo $payload >$out/data.json
  fi
}

export -f call
export RAW
export TYPE
export LOG

# TODO: JOB QUEUE
START="2013-01-01"
END=$(date "+%F")
START_TS=$(date +%s -d $START)
END_TS=$(date +%s -d "2025-12-31")
DAYS=$((($END_TS - $START_TS) / 86400))

# EXTRACT
TICK=$(date +%s%N)
seq 0 $DAYS |
  xargs -I{} date -I -d "$START + {} days" |
  parallel -j10 call
TOCK=$(date +%s%N)
ELAPSED=$((TOCK - TICK))
echo "SCRAPE -- Elapsed time: $((ELAPSED / 1000000)) ms"

# LOAD
TICK=$(date +%s%N)
duckdb -c "copy (from '$RAW/**/*.json') to 'tenders.parquet'"
TOCK=$(date +%s%N)
ELAPSED=$((TOCK - TICK))
echo "LOAD -- Elapsed time: $((ELAPSED / 1000000)) ms"

# TODO: Integrity Check

# Clean Up
mv $LOG archive/$LOG
