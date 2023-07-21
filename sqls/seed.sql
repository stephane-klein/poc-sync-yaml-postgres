SET client_min_messages TO WARNING;

\echo "Database cleaning..."

DROP SCHEMA IF EXISTS public CASCADE;

\echo "Database cleaned"

\echo "'main' schema creating..."
DROP SCHEMA IF EXISTS main CASCADE;
CREATE SCHEMA main;

CREATE TABLE main.feeds (
    slug           VARCHAR(100) PRIMARY KEY,
    name           VARCHAR(100) NOT NULL
);
CREATE INDEX feeds_name_index ON main.feeds (name);

\echo "'main' schema created"
