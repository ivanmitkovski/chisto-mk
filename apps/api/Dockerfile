FROM node:26-alpine AS base
RUN corepack enable && corepack prepare pnpm@10.27.0 --activate
WORKDIR /app

FROM base AS deps
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/api/package.json ./apps/api/
RUN pnpm install --frozen-lockfile

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps/api/node_modules ./apps/api/node_modules
COPY . .
RUN pnpm --filter @chisto/api exec prisma generate
RUN pnpm --filter @chisto/api build

FROM base AS deploy
COPY --from=builder /app/ ./
RUN pnpm --filter @chisto/api deploy --prod --legacy /deployed

FROM base AS runner
ENV NODE_ENV=production
COPY --from=deploy /deployed ./
COPY --from=builder /app/apps/api/docker-entrypoint.sh ./docker-entrypoint.sh
RUN chmod +x ./docker-entrypoint.sh
RUN mkdir -p /opt/prisma-cli && cd /opt/prisma-cli && npm init -y && npm install prisma@7.5.0 dotenv@16 && \
    rm -f package.json package-lock.json
ENV PATH="/opt/prisma-cli/node_modules/.bin:${PATH}"
ENV NODE_PATH="/opt/prisma-cli/node_modules"
EXPOSE 3000
ENTRYPOINT ["./docker-entrypoint.sh"]
