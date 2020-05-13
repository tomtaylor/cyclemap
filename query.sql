SELECT
    - rr.osm_id AS id,
    rr.name,
    rr.ref,
    rr.network,
    ST_LineMerge(
        ST_Collect(
            rm.geometry
            ORDER BY
                rm.index
        )
    ) AS geometry
FROM
    osm_route_relations rr
    INNER JOIN osm_route_members rm ON rm.osm_id = rr.osm_id
    LEFT JOIN osm_ferry_members fm ON fm.member = rm.member
    LEFT JOIN osm_ferry_ways fw ON fw.osm_id = rm.member
WHERE
    rm.type = 1
    AND fm.id IS NULL
    AND fw.id IS NULL
GROUP BY
    rr.osm_id,
    rr.name,
    rr.ref,
    rr.network