#!/usr/bin/env node
import { format } from 'date-fns'
import nunjucks from 'nunjucks';
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

const db_version_datetime = (await pool.query(`SELECT version_datetime FROM sync_yaml_state.resource_states WHERE resource_name='feeds'`)).rows?.[0]?.version_datetime;

const result = (await pool.query(`
    SELECT
        slug,
        name,
        youtube_url,
        description,
        author_name,
        author_wikipedia_fr_url,
        tag_names
    FROM
        main.feeds_with_tag_names
    ORDER BY
        yaml_position
`)).rows;
// console.log(util.inspect(result, {showHidden: false, depth: null, colors: true}))

nunjucks.configure({
    autoescape: false,
    trimBlocks: true,
    lstripBlocks: true
});

console.log(nunjucks.renderString(
    `
version: {{ version }}
feeds:
  {% for item in result %}
  - slug: {{ item.slug }}
    name: {{ item.name }}
    youtube_url: {{ item.youtube_url }}
    author:
      name: {{ item.author_name }}
      wikipedia_fr_url: {{ item.author_wikipedia_fr_url }}
    tags: [{{ item.tag_names | join(", ") }}]
    description: |
      {{ item.description | indent(6) }}
  {% endfor -%}
    `,
    {
        version: format(db_version_datetime, 'yyyy-mm-dd HH:MM:SS'),
        result: result
    }
).trim());

await pool.end();
