import { httpServer } from './app';
import { connectDB } from './config/database';
import { env } from './config/env';
import { logger } from './shared/utils/logger';

async function main() {
  logger.info('Starting Affiliate Platform API...');
  await connectDB();

  httpServer.listen(env.PORT, () => {
    logger.info('API running on http://localhost:' + env.PORT);
  });
}

main().catch((err) => {
  console.error('Fatal startup error:', err);
  process.exit(1);
});
