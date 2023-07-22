#!/usr/bin/env node
// import fs from 'fs';
// import yaml from 'js-yaml';
import nunjucks from 'nunjucks';
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

const result = (await pool.query(`
    SELECT
        slug,
        name
    FROM
        main.feeds
    ORDER BY
        slug
`)).rows;
// console.log(util.inspect(result, {showHidden: false, depth: null, colors: true}))

nunjucks.configure({ autoescape: true });
console.log(nunjucks.renderString(`
{%- for item in result %}- slug: {{ item.slug }}
  name: {{ item.name }}
{% endfor -%}`,
    {result: result}
));

await pool.end();
