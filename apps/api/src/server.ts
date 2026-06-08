import { httpServer } from "./app";
import { connectDB } from "./config/database";
import { redis } from "./config/redis";
import { env } from "./config/env";
import { logger } from "./shared/utils/logger";

async function main() {
  logger.info("Starting Affiliate Platform API...");
  await connectDB();
  await redis.connect();

  httpServer.listen(env.PORT, () => {
    logger.info(`API running on http://localhost:${env.PORT}/api/${env.API_VERSION}`);
    logger.info(`Environment: ${env.NODE_ENV}`);
  });

  process.on("SIGTERM", async () => {
    await redis.quit();
    process.exit(0);
  });
}

main().catch((err) => {
  console.error("Fatal startup error:", err);
  process.exit(1);
});
