SHELL=/bin/bash

dbname := cyclemap_osm

.PHONY: all
all: .dbtimestamp

.dbtimestamp: london_england.osm.pbf mapping.yml
	(psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$(dbname)'" | grep -q 1) || (createdb $(dbname) && psql -d $(dbname) -c "CREATE EXTENSION postgis; CREATE EXTENSION hstore;")
	imposm import -connection postgis://tom@localhost/$(dbname) -read london_england.osm.pbf -mapping mapping.yml -overwritecache -write -deployproduction

london_england.osm.pbf:
	wget https://s3.amazonaws.com/metro-extracts.nextzen.org/london_england.osm.pbf