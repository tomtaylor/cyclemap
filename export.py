#!/usr/bin/env python3
import psycopg2
import psycopg2.extras
import geojson
from geojson import Feature, FeatureCollection, GeometryCollection
import itertools

DB_NAME = "cyclemap_osm"
DB_USER = "tom"
DB_PASSWORD = ""


def main():
    connection = psycopg2.connect(database=DB_NAME, user=DB_USER, password=DB_PASSWORD)
    cursor = connection.cursor(cursor_factory=psycopg2.extras.DictCursor)

    cursor.execute(
        """
        SELECT rm.osm_id, rr.name, rr.network, rr.ref, ST_AsGeoJSON(ST_Transform(geometry, 4326)) AS geojson FROM osm_route_members rm
        LEFT JOIN osm_route_relations rr
        ON rm.osm_id = rr.osm_id
        WHERE ST_Transform(geometry, 4326) && ST_MakeEnvelope(-0.07, 51.52, 0.00, 51.56, 4326)
        ORDER BY rm.osm_id DESC, rm.index ASC
    """
    )

    features = []

    for osm_id, group in itertools.groupby(cursor, lambda x: x["osm_id"]):

        def record_to_geometry(record):
            return geojson.loads(record["geojson"])

        records = list(group)

        if len(records) == 0:
            continue

        geometries = list(map(record_to_geometry, records))

        collection = GeometryCollection(geometries=geometries)
        id = "osm:relation:{}".format(-osm_id)
        feature = Feature(id=id, geometry=collection)

        first_record = records[0]
        name = first_record["name"]
        network = first_record["network"]
        ref = first_record["ref"]

        properties = {"name": name, "network": network, "ref": ref}

        feature.properties = properties

        features.append(feature)

    feature_collection = FeatureCollection(features)

    with open("features.json", "w") as file:
        s = geojson.dumps(feature_collection, sort_keys=True, indent=2)

        file.write(s)


if __name__ == "__main__":
    main()
