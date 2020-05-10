# Notes

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
