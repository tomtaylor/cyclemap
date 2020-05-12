SHELL=/bin/bash

dbname := cyclemap_osm
sql_query := $(shell cat query.sql)

.PHONY: all
all: routes.geojson

routes.geojson: query.sql .dbtimestamp
	rm routes.geojson || true
	ogr2ogr -f GeoJSON routes.geojson -overwrite "PG:host=localhost dbname=$(dbname)"  -sql "$(sql_query)" -t_srs EPSG:4326

.dbtimestamp: great-britain-latest.osm.pbf mapping.yml
	(psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$(dbname)'" | grep -q 1) || (createdb $(dbname) && psql -d $(dbname) -c "CREATE EXTENSION postgis; CREATE EXTENSION hstore;")
	imposm import -connection postgis://tom@localhost/$(dbname) -read great-britain-latest.osm.pbf -mapping mapping.yml -overwritecache -write -deployproduction

great-britain-latest.osm.pbf:
	wget -N http://download.geofabrik.de/europe/great-britain-latest.osm.pbf