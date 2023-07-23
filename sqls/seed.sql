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

CREATE TABLE main.feed_tags (
    id             SERIAL PRIMARY KEY,
    name           TEXT NOT NULL,
    feed_counts INTEGER DEFAULT 0
);
CREATE INDEX feed_tags_name_index           ON main.feed_tags (name);
CREATE INDEX feed_tags_contact_counts_index ON main.feed_tags (feed_counts);

CREATE TABLE main.feeds (
    slug                    VARCHAR(100) PRIMARY KEY,
    yaml_position           INTEGER DEFAULT 0,
    name                    VARCHAR(100) NOT NULL,
    youtube_url             VARCHAR(2000) DEFAULT NULL,
    description             TEXT DEFAULT NULL,
    author_name             VARCHAR(200) DEFAULT NULL,
    author_wikipedia_fr_url VARCHAR(2000) DEFAULT NULL,

    tags     INTEGER[]
);
CREATE INDEX feeds_name_index          ON main.feeds (name);
CREATE INDEX feeds_yaml_position_index ON main.feeds (yaml_position);
CREATE INDEX feeds_tags_index          ON main.feeds USING GIN (tags);

-- main.feeds helper functions

DROP FUNCTION IF EXISTS main.get_and_maybe_insert_feed_tags;
CREATE FUNCTION main.get_and_maybe_insert_feed_tags(
    tag_names VARCHAR[]
) RETURNS INTEGER[] AS $$
    INSERT INTO
        main.feed_tags
    (
        name
    )
    SELECT
        tag_name
    FROM
        UNNEST(tag_names) AS tag_name
    WHERE
        tag_name NOT IN (
            SELECT feed_tags.name
            FROM main.feed_tags
            WHERE feed_tags.name = tag_name
        );

    SELECT
        ARRAY_AGG(feed_tags.id) AS tags
    FROM
        UNNEST(tag_names) AS tag_name
    LEFT JOIN
        main.feed_tags
    ON
        feed_tags.name = tag_name;
$$ LANGUAGE SQL;

-- main.feed_tags triggers

DROP FUNCTION IF EXISTS main.compute_feed_tags_cache;
CREATE FUNCTION main.compute_feed_tags_cache(
    tag_ids INTEGER[]
) RETURNS VOID AS $$
    UPDATE
        main.feed_tags
    SET
        feed_counts=feed_count_computation.feed_count
    FROM (
        SELECT
            feed_tags.id AS feed_tag_id,
            COUNT(feeds.slug) AS feed_count
        FROM
            main.feed_tags
        LEFT JOIN
            main.feeds
        ON
            feed_tags.id = ANY(feeds.tags)
        WHERE
            feed_tags.id = ANY(tag_ids)
        GROUP BY feed_tags.id
    ) AS feed_count_computation
    WHERE
        feed_tags.id=feed_count_computation.feed_tag_id;
$$ LANGUAGE SQL;

\echo "on_feed_tags_updated_then_compute_feed_tags_cache trigger creating..."

DROP TRIGGER IF EXISTS on_feed_tags_updated_then_compute_feed_tags_cache ON main.feeds;
DROP FUNCTION IF EXISTS main.on_feed_tags_updated_then_compute_feed_tags_cache();

CREATE FUNCTION main.on_feed_tags_updated_then_compute_feed_tags_cache() RETURNS TRIGGER AS $$
BEGIN
    PERFORM main.compute_feed_tags_cache(
        ARRAY(
            SELECT DISTINCT *
            FROM UNNEST(
                ARRAY_CAT(
                    OLD.tags,
                    NEW.tags
                )
            )
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_feed_tags_updated_then_compute_feed_tags_cache
    AFTER UPDATE
    ON main.feeds
    FOR EACH ROW
    WHEN (OLD.tags IS DISTINCT FROM  NEW.tags)
    EXECUTE PROCEDURE main.on_feed_tags_updated_then_compute_feed_tags_cache();

\echo "... on_feed_tags_updated_then_compute_feed_tags_cache created"

-- Triggers to auto update sync_yaml_state.resource_states.version_datetime

\echo "on_feed_tags_inserted_then_compute_feed_tags_cache trigger creating..."

DROP TRIGGER IF EXISTS on_feed_tags_inserted_then_compute_feed_tags_cache ON main.feeds;
DROP FUNCTION IF EXISTS on_feed_tags_inserted_then_compute_feed_tags_cache();

CREATE FUNCTION main.on_feed_tags_inserted_then_compute_feed_tags_cache() RETURNS TRIGGER AS $$
BEGIN
    PERFORM main.compute_feed_tags_cache(NEW.tags);

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE TRIGGER on_feed_tags_inserted_then_compute_feed_tags_cache
    AFTER INSERT
    ON main.feeds
    FOR EACH ROW
    EXECUTE PROCEDURE main.on_feed_tags_inserted_then_compute_feed_tags_cache();

\echo "... on_feed_tags_inserted_then_compute_feed_tags_cache created"

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
