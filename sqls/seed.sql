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
    version_datetime  TIMESTAMP WITHOUT TIME ZONE NOT NULL
);
CREATE INDEX resource_states_resurce_name_index ON sync_yaml_state.resource_states (resource_name);

CREATE TABLE main.feeds (
    slug          VARCHAR(100) PRIMARY KEY,
    yaml_position INTEGER DEFAULT 0,
    name          VARCHAR(100) NOT NULL
);
CREATE INDEX feeds_name_index ON main.feeds (name);
CREATE INDEX feeds_yaml_position_index ON main.feeds (yaml_position);

DROP TRIGGER IF EXISTS on_feeds_update_version_datetime ON main.feeds;
DROP FUNCTION IF EXISTS main.on_feeds_update_version_datetime();

CREATE FUNCTION main.on_feeds_update_version_datetime() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO sync_yaml_state.resource_states
    (
        resource_name,
        version_datetime
    )
    VALUES(
        'feeds',
        NOW()
    )
    ON CONFLICT (resource_name) DO UPDATE
        SET version_datetime=NOW();

    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_feeds_update_version_datetime
    AFTER INSERT OR UPDATE OR DELETE
    ON main.feeds
    FOR EACH ROW
    EXECUTE PROCEDURE main.on_feeds_update_version_datetime();

\echo "'main' schema created"
