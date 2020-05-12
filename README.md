# UK Cyclemap Data

A collection of tooling for building vector data and tiles of UK cycle networks from OpenStreetMap data. 

## Setup

Install postgres, postgis, imposm and ogr2ogr.

Run `make` to spool through the build tasks and hopefully spit out `routes.geojson` at the end of it.

# Notes to self

Find cycleways that aren't part of cycle network route relations.

```sql
SELECT COUNT(*)
FROM osm_highways h
WHERE highway = 'cycleway'
OR (highway = 'footway' AND bicycle IS TRUE)
AND NOT EXISTS (
	SELECT
	FROM osm_route_members rm
	WHERE rm.member = h.osm_id
)
```
