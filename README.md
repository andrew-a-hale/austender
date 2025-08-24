# Austender Scraper

## Endpoint

BASE: `https://api.tenders.gov.au`

ENDPOINT: `/ocds/findByDates/<dateType>/<start:yyyy-mm-ddThh:MM:ssZ>/<end:yyyy-mm-ddThh:MM:ssZ>`

### Date Type

- `contractPublished`: returns only Parent CNs published in the date range, NOT Amendments
- `contractLastModified`: returns amendments only
- `contractStart`: returns Parent and Amendment CNs where the Contract start date is in the date range
- `contractEnd`: returns Parent and Amendment CNs where the Contract end date is in the date range

### Date Format

- Start: `2013-01-01T00:00:00Z`
- End: `2025-12-31T23:59:59Z`

### Example

`https://api.tenders.gov.au/ocds/findByDates/contractStart/2025-08-15T00:00:00Z/2025-08-16T00:00:00Z`

## Dependencies

- `bash`
- `duckdb`
- `gnu parallel`
- `jq`
- `curl`

## TODO

- `gum` script
