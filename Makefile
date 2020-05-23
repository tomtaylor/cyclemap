SHELL=/bin/bash

dbname := cyclemap_osm

.PHONY: all
all: routes.mbtiles

.PHONY: preview
preview:
	mbview routes.mbtiles

.PHONY: upload
upload: routes.mbtiles
	mapbox upload tomtaylor.8efgkmxv --name "Cycle Network" routes.mbtiles

routes.mbtiles: routes.geojson
	tippecanoe -o $@ -P -S 3 --force -l routes --drop-densest-as-needed -z14 routes.geojson

routes.mbtiles: routes.geojson

routes.geojson: query.sql .dbtimestamp
	rm routes.geojson || true
	ogr2ogr -f GeoJSONSeq routes.geojson "PG:host=localhost dbname=$(dbname)" -sql @query.sql -t_srs EPSG:4326

.dbtimestamp: great-britain-latest.osm.pbf ireland-and-northern-ireland-latest.osm.pbf mapping.yml
	(psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$(dbname)'" | grep -q 1) || (createdb $(dbname) && psql -d $(dbname) -c "CREATE EXTENSION postgis; CREATE EXTENSION hstore;")
	imposm import -read great-britain-latest.osm.pbf -mapping mapping.yml -overwritecache
	imposm import -read ireland-and-northern-ireland-latest.osm.pbf -mapping mapping.yml -appendcache
	imposm import -connection postgis://tom@localhost/$(dbname) -mapping mapping.yml -write -deployproduction
	touch .dbtimestamp

great-britain-latest.osm.pbf: download
ireland-and-northern-ireland-latest.osm.pbf: download

.PHONY: download
download:
	wget -N http://download.geofabrik.de/europe/great-britain-latest.osm.pbf
	wget -N http://download.geofabrik.de/europe/ireland-and-northern-ireland-latest.osm.pbf
