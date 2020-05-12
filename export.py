#!/usr/bin/env python3
import re
import psycopg2
import psycopg2.extras
import geojson
from geojson import Feature, FeatureCollection, GeometryCollection
import itertools
from shapely.geometry import shape
from shapely.ops import linemerge

DB_NAME = "cyclemap_osm"
DB_USER = "tom"
DB_PASSWORD = ""

CYCLE_SUPERHIGHWAY_REF_REGEXP = r"^CS[0-9]+$"
CYCLEWAY_REF_REGEXP = r"^C[0-9]+$"
QUIETWAY_REF_REGEXP = r"^Q[0-9]+$"


def main():
    connection = psycopg2.connect(database=DB_NAME, user=DB_USER, password=DB_PASSWORD)
    cursor = connection.cursor(cursor_factory=psycopg2.extras.DictCursor)

    cursor.execute(
        """
        SELECT rm.osm_id, rr.name, rr.network, rr.ref, ST_AsGeoJSON(ST_Transform(geometry, 4326)) AS geojson FROM osm_route_members rm
        LEFT JOIN osm_route_relations rr
        ON rm.osm_id = rr.osm_id
        WHERE type = 1
        --AND WHERE ST_Transform(geometry, 4326) && ST_MakeEnvelope(-0.097880,51.520501,0.012498,51.572597, 4326)
        ORDER BY rm.osm_id DESC, rm.index ASC
    """
    )

    features = []

    for osm_id, group in itertools.groupby(cursor, lambda x: x["osm_id"]):

        def record_to_shape(record):
            return shape(geojson.loads(record["geojson"]))

        records = list(group)

        if len(records) == 0:
            continue

        shapes = list(map(record_to_shape, records))
        id = "osm:relation:{}".format(-osm_id)

        multilinestring = linemerge(shapes)
        feature = Feature(id=id, geometry=multilinestring)
        # geometry_collection = GeometryCollection(geometries=shapes)
        # feature = Feature(id=id, geometry=geometry_collection)

        first_record = records[0]
        name = first_record["name"]
        network = first_record["network"]
        ref = first_record["ref"]
        route_type = detect_route_type(first_record)

        print(
            "Exporting '{}' network={} ref={} route_type={}".format(
                name, network, ref, route_type
            )
        )

        properties = {
            "name": name,
            "network": network,
            "ref": ref,
            "route_type": route_type,
        }

        feature.properties = properties

        features.append(feature)

    feature_collection = FeatureCollection(features)

    with open("features.json", "w") as file:
        s = geojson.dumps(feature_collection, sort_keys=True, indent=2)

        file.write(s)


def detect_route_type(record):
    if record["network"] == "ncn":
        return "ncn"

    if re.match(CYCLE_SUPERHIGHWAY_REF_REGEXP, record["ref"]):
        return "superhighway"

    if re.match(CYCLEWAY_REF_REGEXP, record["ref"]):
        return "cycleway"

    if re.match(QUIETWAY_REF_REGEXP, record["ref"]):
        return "quietway"

    if record["network"] == "lcn":
        return "lcn"

    return None


if __name__ == "__main__":
    main()
