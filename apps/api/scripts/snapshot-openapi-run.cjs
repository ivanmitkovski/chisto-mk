/**
 * OpenAPI snapshot generator (CI: `pnpm snapshot:openapi:check`).
 * Requires a prior `nest build` or `pnpm build` so `dist/` exists (Swagger reads @ApiProperty metadata from compiled output).
 */
'use strict';

require('reflect-metadata');
require('dotenv/config');

const { mkdirSync, readFileSync, writeFileSync, existsSync } = require('node:fs');
const { join } = require('node:path');
const { NestFactory } = require('@nestjs/core');
const { DocumentBuilder, SwaggerModule } = require('@nestjs/swagger');

const OUT_DIR = join(__dirname, '..', 'openapi');
const OUT_FILE = join(OUT_DIR, 'openapi.snapshot.json');

/**
 * Pin env before AppModule loads — dynamic modules read process.env at import time.
 * Keeps the committed contract stable across local `.env`, CI `NODE_ENV=test`, etc.
 */
function pinOpenApiSnapshotEnv() {
  process.env.NODE_ENV = 'development';
  process.env.MAP_PROJECTION_WORKER_ENABLED = 'false';
  process.env.MAP_LIFECYCLE_CRON_ENABLED = 'false';
  process.env.PUSH_FCM_ENABLED = 'false';
  delete process.env.METRICS_BEARER_TOKEN;
  delete process.env.DISCOVERY_ANALYTICS_INGEST_SECRET;

  if (!process.env.JWT_SECRET?.trim()) {
    process.env.JWT_SECRET = 'openapi_snapshot_jwt_secret_min_32_chars';
  }
  if (!process.env.DATABASE_URL?.trim()) {
    process.env.DATABASE_URL = 'postgresql://openapi:openapi@127.0.0.1:5432/openapi_snapshot';
  }
  // OpenAPI generation only needs Swagger metadata — skip Redis so local snapshot works without a broker.
  delete process.env.REDIS_URL;
}

pinOpenApiSnapshotEnv();

const { AppModule } = require('../dist/app.module');
const { validateEnv } = require('../dist/config/env');

async function main() {
  const check = process.argv.includes('--check');
  validateEnv();
  const app = await NestFactory.create(AppModule, { logger: false, abortOnError: false });
  await app.init();

  const config = new DocumentBuilder()
    .setTitle('Chisto.mk API')
    .setDescription('Civic environmental platform — pollution reporting, site lifecycle, cleanup events')
    .setVersion('0.1.0')
    .build();
  let document;
  try {
    document = SwaggerModule.createDocument(app, config, { deepScanRoutes: false });
  } catch (err) {
    console.error('[openapi-snapshot] SwaggerModule.createDocument failed:', err);
    process.exit(1);
  }

  const json = `${JSON.stringify(document, null, 2)}\n`;
  mkdirSync(OUT_DIR, { recursive: true });

  const parsed = JSON.parse(json);
  if (!parsed.paths || Object.keys(parsed.paths).length === 0) {
    console.error(
      'OpenAPI snapshot has no paths — generation may have silently failed. Regenerate with: pnpm snapshot:openapi',
    );
    process.exit(1);
  }

  if (check) {
    if (!existsSync(OUT_FILE)) {
      throw new Error(`Missing baseline ${OUT_FILE}; run snapshot:openapi without --check first.`);
    }
    const existing = readFileSync(OUT_FILE, 'utf8');
    if (existing !== json) {
      throw new Error(
        'OpenAPI snapshot drift: run `pnpm snapshot:openapi` and commit openapi/openapi.snapshot.json',
      );
    }
    console.log('OpenAPI snapshot OK (no drift).');
    return;
  }

  writeFileSync(OUT_FILE, json, 'utf8');
  console.log(`Wrote ${OUT_FILE}`);
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((err) => {
    console.error('[openapi-snapshot] failed:', err);
    process.exit(1);
  });
