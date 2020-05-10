SHELL=/bin/bash

dbname := cyclemap_osm

.PHONY: all
all: .dbtimestamp

.dbtimestamp: great-britain-latest.osm.pbf mapping.yml
	(psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$(dbname)'" | grep -q 1) || (createdb $(dbname) && psql -d $(dbname) -c "CREATE EXTENSION postgis; CREATE EXTENSION hstore;")
	imposm import -connection postgis://tom@localhost/$(dbname) -read great-britain-latest.osm.pbf -mapping mapping.yml -overwritecache -write -deployproduction

great-britain-latest.osm.pbf:
	wget http://download.geofabrik.de/europe/great-britain-latest.osm.pbf