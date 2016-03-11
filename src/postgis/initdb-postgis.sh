#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

function create_template_postgis() {
    PGUSER="$POSTGRES_USER" psql --dbname="$POSTGRES_DB" <<-'EOSQL'
		CREATE DATABASE template_postgis;
		UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';
	EOSQL
}

function execute_sql_into_template() {
    local sql_file="$1"
    PGUSER="$POSTGRES_USER" psql --dbname="template_postgis" -f "$sql_file"
}

function install_cartodb() {
    echo "Loading CartoDB XYZ functions into template_postgis"
    execute_sql_into_template "$CARTODB_DIR/CDB_XYZ.sql"
}

function install_vt_util() {
    echo "Loading vt-util functions into template_postgis"
    execute_sql_into_template "$VT_UTIL_DIR/postgis-vt-util.sql"
}

function create_postgis_extensions() {
    cd "/usr/share/postgresql/$PG_MAJOR/contrib/postgis-$POSTGIS_MAJOR"
    local db
    for db in template_postgis "$POSTGRES_DB"; do
        echo "Loading PostGIS into $db"
        PGUSER="$POSTGRES_USER" psql --dbname="$db" <<-'EOSQL'
			CREATE EXTENSION postgis;
			CREATE EXTENSION postgis_topology;
			CREATE EXTENSION hstore;
			CREATE EXTENSION osm2vectortiles;
		EOSQL
    done
    }

function main() {
    create_template_postgis
    create_postgis_extensions
    install_vt_util
    install_cartodb
}

main