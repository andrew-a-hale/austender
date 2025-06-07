# Austender Scraper

ENDPOINT: `https://api.tenders.gov.au/ocds/findByDates/<dateType>/<start:yyyy-mm-ddThh:MM:ssZ>/<end:yyyy-mm-ddThh:MM:ssZ>`

DATETYPE:

    - contractPublished
    - contractLastModified
    - contractStart
    - contractEnd

RANGE:

    - Start: `2013-01-01T00:00:00Z`
    - End: `2025-12-31T23:59:59Z`

Call by Day
-> land in datalake partition by day
-> silver layer ???
-> gold layer ???
-> mart layer ???

Integrity Check?
Logging?
Job Queue?
