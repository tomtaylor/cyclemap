SELECT
    /* Invert the OSM ID, because imposm uses negative IDs for relations */
    - rr.osm_id AS id,
    rr.name,
    rr.ref,
    rr.network,
    ST_LineMerge(
        ST_Collect(
            rm.geometry
            /* Order by index so we assemble the linestring in the right order */
            ORDER BY
                rm.index
        )
    ) AS geometry,
    ROUND(SUM(ST_Length(rm.geometry))) AS length
FROM
    osm_route_relations rr
    INNER JOIN osm_route_members rm ON rm.osm_id = rr.osm_id
    /* Join these to exclude ferry relation members */
    LEFT JOIN osm_ferry_members fm ON fm.member = rm.member
    /* Join these to exclude ferry ways */
    LEFT JOIN osm_ferry_ways fw ON fw.osm_id = rm.member
WHERE
    /* Only import ways, not any nodes that might be part of the relation */
    rm.type = 1
    AND fm.id IS NULL
    AND fw.id IS NULL
GROUP BY
    rr.osm_id,
    rr.name,
    rr.ref,
    rr.network