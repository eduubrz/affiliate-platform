import dotenv from "dotenv";
dotenv.config();

function required(key: string): string {
  const value = process.env[key];
  if (!value) throw new Error(`Missing required env var: ${key}`);
  return value;
}

export const env = {
  NODE_ENV: process.env.NODE_ENV || "development",
  PORT: parseInt(process.env.PORT || "4000"),
  API_VERSION: process.env.API_VERSION || "v1",
  FRONTEND_URL: process.env.FRONTEND_URL || "http://localhost:3000",
  DATABASE_URL: process.env.DATABASE_URL || "",
  REDIS_URL: process.env.REDIS_URL || "redis://localhost:6379",
  REDIS_PASSWORD: process.env.REDIS_PASSWORD,
  JWT_ACCESS_SECRET: process.env.JWT_ACCESS_SECRET || "dev-secret-change-in-production-32chars",
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || "dev-refresh-change-in-production-32ch",
  JWT_ACCESS_EXPIRES: process.env.JWT_ACCESS_EXPIRES || "15m",
  JWT_REFRESH_EXPIRES: process.env.JWT_REFRESH_EXPIRES || "30d",
  OPENAI_API_KEY: process.env.OPENAI_API_KEY || "",
  OPENAI_MODEL: process.env.OPENAI_MODEL || "gpt-4o",
  OPENAI_MAX_TOKENS: parseInt(process.env.OPENAI_MAX_TOKENS || "1000"),
  STORAGE_ENDPOINT: process.env.STORAGE_ENDPOINT || "http://localhost:9000",
  STORAGE_ACCESS_KEY: process.env.STORAGE_ACCESS_KEY || "minioadmin",
  STORAGE_SECRET_KEY: process.env.STORAGE_SECRET_KEY || "minioadmin",
  STORAGE_BUCKET: process.env.STORAGE_BUCKET || "affiliate-banners",
  STORAGE_REGION: process.env.STORAGE_REGION || "us-east-1",
  STORAGE_USE_SSL: process.env.STORAGE_USE_SSL === "true",
  STORAGE_PUBLIC_URL: process.env.STORAGE_PUBLIC_URL || "http://localhost:9000/affiliate-banners",
  SCRAPER_TIMEOUT: parseInt(process.env.SCRAPER_TIMEOUT || "15000"),
  SCRAPER_USER_AGENT: process.env.SCRAPER_USER_AGENT || "Mozilla/5.0",
  WHATSAPP_API_URL: process.env.WHATSAPP_API_URL,
  WHATSAPP_API_KEY: process.env.WHATSAPP_API_KEY,
  WHATSAPP_INSTANCE: process.env.WHATSAPP_INSTANCE || "affiliate-bot",
  TRACKING_BASE_URL: process.env.TRACKING_BASE_URL || "http://localhost:4000/t",
  RATE_LIMIT_WINDOW_MS: parseInt(process.env.RATE_LIMIT_WINDOW_MS || "900000"),
  RATE_LIMIT_MAX_REQUESTS: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || "100"),
  LOG_LEVEL: process.env.LOG_LEVEL || "info",
};
