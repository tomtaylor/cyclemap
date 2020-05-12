SELECT
    - rr.osm_id AS id,
    rr.name,
    rr.ref,
    rr.network,
    CASE
        WHEN network = 'ncn' THEN 'national'
        WHEN ref ~ '^C[0-9]+' THEN 'london-cycleway'
        WHEN name ILIKE '%cycleway%' THEN 'london-cycleway'
        WHEN ref ~ '^CS[0-9]+' THEN 'london-superhighway'
        WHEN ref ~ '^Q[0-9]+' THEN 'london-quietway'
        WHEN name ILIKE '%quietway%' THEN 'london-quietway'
        WHEN network = 'icn' THEN 'international'
        ELSE 'other'
    END AS route_type,
    ST_LineMerge(ST_Collect(geometry ORDER BY rm.index)) AS geometry
FROM
    osm_route_relations rr
    INNER JOIN osm_route_members rm ON rm.osm_id = rr.osm_id
WHERE
    type = 1
GROUP BY
    rr.osm_id,
    rr.name,
    rr.ref,
    rr.network