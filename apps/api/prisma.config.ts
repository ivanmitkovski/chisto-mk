try {
  require('dotenv/config');
} catch {
  // dotenv not in image; DATABASE_URL from env (e.g. ECS task definition)
}
import { defineConfig, env } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'tsx prisma/seed.ts',
  },
  datasource: {
    url: env('DATABASE_URL'),
  },
});
