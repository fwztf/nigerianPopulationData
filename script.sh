#!/bin/bash
set -e # quit on error
#set -x # debug mode on

CSV_FILE="nigerian_cities.csv"
EXPORT_FILE="nigerian_cities_with_region.csv"

# define PSQL variable to use psql interactive terminal
PSQL="psql -U postgres -c"

# define database name
DB_NAME="nigeria_population_figures_2024"

# check if DB exists
echo "checking if database: $DB_NAME exists"
DB_EXISTS=$($PSQL "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -o '1')
echo "DB_EXISTS: '$DB_EXISTS'"

# create database ONLY if it doesn't already exist
if [[ -z "$DB_EXISTS" ]] then
    echo "Database $DB_NAME does not exist. Creating it..."
    $PSQL "CREATE DATABASE $DB_NAME;"
else
    echo "Database $DB_NAME already exists."
fi

# update PSQL and connect to DB
PSQL="psql -U postgres -d $DB_NAME -c"

# create cities table
$PSQL "CREATE TABLE IF NOT EXISTS cities(city_id SERIAL PRIMARY KEY, city VARCHAR(45), country VARCHAR(10), population INT, latitude FLOAT, longitude FLOAT, region VARCHAR(15));"

# import csv data
$PSQL "\COPY cities(city, country, population, latitude, longitude) FROM '$CSV_FILE' DELIMITER ',' CSV HEADER;"

# update table by classifying data into north or south
$PSQL "UPDATE cities SET region = CASE WHEN latitude >= 9.99999 THEN 'North' ELSE 'South' END;"

# export updated table to new CSV file
$PSQL "COPY cities TO STDOUT WITH CSV HEADER;" > "$EXPORT_FILE"
echo "processing complete..."
echo "export file ready"
