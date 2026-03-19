#!/bin/sh
set -e
cd /app
prisma generate
prisma migrate deploy
exec node dist/main.js
