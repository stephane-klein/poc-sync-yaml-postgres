#!/usr/bin/env node
import fs from 'fs';
import yaml from 'js-yaml';
import util from 'util';
import pkg from "pg";
const { Pool } = pkg;
process.env.TZ = "UTC+0";

const pool = new Pool({
    user: process.env.POSTGRES_USER || "postgres",
    host: process.env.POSTGRES_HOST || "127.0.0.1",
    database: process.env.POSTGRES_DB || "postgres",
    password: process.env.POSTGRES_PASSWORD || "password",
    port: process.env.POSTGRES_PORT || 5432
});

try {
    const data = yaml.load(fs.readFileSync('./feeds.yaml', 'utf8'));

    const db_version_datetime = (await pool.query(`SELECT version_datetime FROM sync_yaml_state.resource_states WHERE resource_name='feeds'`)).rows?.[0]?.version_datetime;

    if (
        (db_version_datetime === undefined) ||
        (db_version_datetime <= data.version)
    ) {
        await pool.query('ALTER TABLE main.feeds DISABLE TRIGGER on_feeds_update_version_datetime;');
        data.feeds.forEach(async(item) => {
            await pool.query(
                `
                    INSERT INTO main.feeds
                    (
                        slug,
                        name
                    )
                    VALUES(
                        $1,
                        $2
                    ) ON CONFLICT (slug) DO UPDATE
                        SET name=$2;
                `,
                [
                    item.slug,
                    item.name
                ]
            );
        });
        await pool.query(
            `
            INSERT INTO sync_yaml_state.resource_states
            (
                resource_name,
                version_datetime
            )
            VALUES(
                'feeds',
                $1
            )
            ON CONFLICT (resource_name) DO UPDATE
                SET version_datetime=$1
            `,
            [
                data.version
            ]
        );
        await pool.query('ALTER TABLE main.feeds ENABLE TRIGGER on_feeds_update_version_datetime;');
    } else {
        console.log(`The "feeds" table contains changes made after ${data.version} therefore, the synchronization has not been executed`);
    }

    // console.log(util.inspect(data, {showHidden: false, depth: null, colors: true}))
} catch (e) {
    console.log(e);
}

await pool.end();
