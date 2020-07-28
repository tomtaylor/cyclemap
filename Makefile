SHELL=/bin/bash

DBNAME := cyclemap_osm
OSM_SOURCES := europe/great-britain-latest.osm.pbf europe/ireland-and-northern-ireland-latest.osm.pbf australia-oceania/australia-latest.osm.pbf australia-oceania/new-zealand-latest.osm.pbf north-america/canada-latest.osm.pbf north-america/us-latest.osm.pbf
OSM_PATHS := $(addprefix osm/,${OSM_SOURCES})

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
	ogr2ogr -f GeoJSONSeq routes.geojson "PG:host=localhost dbname=$(DBNAME)" -sql @query.sql -t_srs EPSG:4326

.dbtimestamp: $(OSM_PATHS) mapping.yml
	(psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$(DBNAME)'" | grep -q 1) || (createdb $(DBNAME) && psql -d $(DBNAME) -c "CREATE EXTENSION postgis; CREATE EXTENSION hstore;")

	@i=0; \
	for source in ${OSM_PATHS}; do \
		if [ $$i -eq 0 ]; then \
			imposm import -read $${source} -mapping mapping.yml -overwritecache ;\
		else \
			imposm import -read $${source} -mapping mapping.yml -appendcache ; \
		fi; \
		i=$$(expr $$i + 1); \
	done

	imposm import -connection postgis://tom@localhost/$(DBNAME) -mapping mapping.yml -write -deployproduction
	touch .dbtimestamp


osm/%.osm.pbf:
	mkdir -p $(dir $@)
	wget -N https://download.geofabrik.de/$(subst osm/,,$@) -P $(dir $@)

.PHONY: download
download: $(OSM_PATHS)