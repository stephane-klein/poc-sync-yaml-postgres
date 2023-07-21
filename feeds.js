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

    // console.log(util.inspect(data, {showHidden: false, depth: null, colors: true}))
} catch (e) {
    console.log(e);
}

await pool.end();
