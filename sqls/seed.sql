SET client_min_messages TO WARNING;

\echo "Database cleaning..."

DROP SCHEMA IF EXISTS public CASCADE;

\echo "Database cleaned"

\echo "'main' schema creating..."
DROP SCHEMA IF EXISTS main CASCADE;
CREATE SCHEMA main;

DROP SCHEMA IF EXISTS sync_yaml_state CASCADE;
CREATE SCHEMA sync_yaml_state;

CREATE TABLE sync_yaml_state.resource_states (
    resource_name     VARCHAR(100) PRIMARY KEY,
    version_datetime  TIMESTAMP NOT NULL
);
CREATE INDEX resource_states_resurce_name_index ON sync_yaml_state.resource_states (resource_name);

CREATE TABLE main.feeds (
    slug  VARCHAR(100) PRIMARY KEY,
    name  VARCHAR(100) NOT NULL
);
CREATE INDEX feeds_name_index ON main.feeds (name);

\echo "'main' schema created"
