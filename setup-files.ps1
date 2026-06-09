# ============================================================
# setup-files.ps1 — Cria todos os arquivos do projeto
# Execute com: powershell -ExecutionPolicy Bypass -File setup-files.ps1
# ============================================================

Write-Host "Criando arquivos do projeto AffiliateOS..." -ForegroundColor Cyan

# ─── config/redis.ts ──────────────────────────────────────
Set-Content -Path "apps/api/src/config/redis.ts" -Value @'
import { Redis } from "ioredis";

export const redis = new Redis(process.env.REDIS_URL || "redis://localhost:6379", {
  maxRetriesPerRequest: null,
  enableReadyCheck: false,
  lazyConnect: true,
});

redis.on("connect", () => console.log("Redis connected"));
redis.on("error", (err) => console.error("Redis error:", err));
'@

# ─── config/env.ts ────────────────────────────────────────
Set-Content -Path "apps/api/src/config/env.ts" -Value @'
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
'@

# ─── shared/utils/AppError.ts ─────────────────────────────
Set-Content -Path "apps/api/src/shared/utils/AppError.ts" -Value @'
export class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number = 500,
    public code?: string
  ) {
    super(message);
    this.name = "AppError";
    Error.captureStackTrace(this, this.constructor);
  }
}
'@

# ─── shared/utils/asyncHandler.ts ─────────────────────────
Set-Content -Path "apps/api/src/shared/utils/asyncHandler.ts" -Value @'
import { Request, Response, NextFunction, RequestHandler } from "express";

export const asyncHandler = (fn: Function): RequestHandler => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
'@

# ─── shared/utils/logger.ts ───────────────────────────────
Set-Content -Path "apps/api/src/shared/utils/logger.ts" -Value @'
import winston from "winston";

const { combine, timestamp, colorize, printf } = winston.format;

const devFormat = printf(({ level, message, timestamp }) => {
  return `${timestamp} [${level}]: ${message}`;
});

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || "info",
  format: combine(
    timestamp({ format: "YYYY-MM-DD HH:mm:ss" }),
    process.env.NODE_ENV === "production"
      ? winston.format.json()
      : combine(colorize(), devFormat)
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: "logs/error.log", level: "error" }),
    new winston.transports.File({ filename: "logs/combined.log" }),
  ],
});
'@

# ─── shared/middleware/errorHandler.ts ────────────────────
Set-Content -Path "apps/api/src/shared/middleware/errorHandler.ts" -Value @'
import { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import { AppError } from "../utils/AppError";
import { logger } from "../utils/logger";

export const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction
) => {
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: "Validation error",
      details: err.errors.map((e) => ({ field: e.path.join("."), message: e.message })),
    });
  }
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ error: err.message, code: err.code });
  }
  if ((err as any).code === "P2002") {
    return res.status(409).json({ error: "Resource already exists" });
  }
  if ((err as any).code === "P2025") {
    return res.status(404).json({ error: "Resource not found" });
  }
  logger.error("Unhandled error:", { message: err.message, url: req.url });
  res.status(500).json({
    error: process.env.NODE_ENV === "production" ? "Internal server error" : err.message,
  });
};
'@

# ─── shared/middleware/requestLogger.ts ───────────────────
Set-Content -Path "apps/api/src/shared/middleware/requestLogger.ts" -Value @'
import { Request, Response, NextFunction } from "express";
import { logger } from "../utils/logger";

export const requestLogger = (req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();
  res.on("finish", () => {
    const duration = Date.now() - start;
    const level = res.statusCode >= 500 ? "error" : res.statusCode >= 400 ? "warn" : "http";
    logger[level](`${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`);
  });
  next();
};
'@

# ─── app.ts ───────────────────────────────────────────────
Set-Content -Path "apps/api/src/app.ts" -Value @'
import express, { Application, Request, Response } from "express";
import cors from "cors";
import helmet from "helmet";
import compression from "compression";
import rateLimit from "express-rate-limit";
import { createServer } from "http";
import { Server as SocketIO } from "socket.io";
import { env } from "./config/env";
import { logger } from "./shared/utils/logger";
import { errorHandler } from "./shared/middleware/errorHandler";
import { requestLogger } from "./shared/middleware/requestLogger";
import authRoutes from "./modules/auth/auth.routes";
import productRoutes from "./modules/products/product.routes";
import aiRoutes from "./modules/ai/ai.routes";
import analyticsRoutes from "./modules/analytics/analytics.routes";
import whatsappRoutes from "./modules/whatsapp/whatsapp.routes";
import schedulerRoutes from "./modules/scheduler/scheduler.routes";
import adminRoutes from "./modules/admin/admin.routes";
import trackingRoutes from "./modules/tracking/tracking.routes";
import campaignRoutes from "./modules/campaigns/campaign.routes";

const app: Application = express();
const httpServer = createServer(app);

export const io = new SocketIO(httpServer, {
  cors: { origin: env.FRONTEND_URL, methods: ["GET", "POST"] },
});

io.on("connection", (socket) => {
  socket.on("join-dashboard", (userId: string) => {
    socket.join(`user:${userId}`);
  });
});

app.use(helmet({ crossOriginResourcePolicy: { policy: "cross-origin" } }));
app.use(cors({ origin: env.FRONTEND_URL, credentials: true }));
app.use(rateLimit({ windowMs: env.RATE_LIMIT_WINDOW_MS, max: env.RATE_LIMIT_MAX_REQUESTS }));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));
app.use(compression());
app.use(requestLogger);

app.get("/health", (_req: Request, res: Response) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

const apiRouter = express.Router();
apiRouter.use("/auth", authRoutes);
apiRouter.use("/products", productRoutes);
apiRouter.use("/captions", aiRoutes);
apiRouter.use("/analytics", analyticsRoutes);
apiRouter.use("/whatsapp", whatsappRoutes);
apiRouter.use("/scheduler", schedulerRoutes);
apiRouter.use("/admin", adminRoutes);
apiRouter.use("/campaigns", campaignRoutes);

app.use(`/api/${env.API_VERSION}`, apiRouter);
app.use("/t", trackingRoutes);
app.use((_req: Request, res: Response) => res.status(404).json({ error: "Route not found" }));
app.use(errorHandler);

export { app, httpServer };
'@

# ─── server.ts ────────────────────────────────────────────
Set-Content -Path "apps/api/src/server.ts" -Value @'
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
'@

# ─── auth/auth.service.ts ─────────────────────────────────
Set-Content -Path "apps/api/src/modules/auth/auth.service.ts" -Value @'
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { prisma } from "../../config/database";
import { env } from "../../config/env";
import { AppError } from "../../shared/utils/AppError";
import { logger } from "../../shared/utils/logger";

export class AuthService {
  async register(dto: { email: string; password: string; name: string }) {
    const existing = await prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) throw new AppError("Email already in use", 409);
    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await prisma.user.create({
      data: { email: dto.email.toLowerCase().trim(), passwordHash, name: dto.name.trim() },
    });
    const tokens = await this.generateTokens(user.id);
    const { passwordHash: _ph, ...safeUser } = user;
    return { user: safeUser, tokens };
  }

  async login(dto: { email: string; password: string }) {
    const user = await prisma.user.findUnique({ where: { email: dto.email.toLowerCase() } });
    if (!user || !user.isActive) throw new AppError("Invalid credentials", 401);
    const match = await bcrypt.compare(dto.password, user.passwordHash);
    if (!match) throw new AppError("Invalid credentials", 401);
    await prisma.user.update({ where: { id: user.id }, data: { lastLoginAt: new Date() } });
    const tokens = await this.generateTokens(user.id);
    logger.info(`User logged in: ${user.email}`);
    const { passwordHash: _ph, ...safeUser } = user;
    return { user: safeUser, tokens };
  }

  async refreshToken(token: string) {
    const stored = await prisma.refreshToken.findUnique({ where: { token } });
    if (!stored || stored.revokedAt || stored.expiresAt < new Date()) {
      throw new AppError("Invalid or expired refresh token", 401);
    }
    await prisma.refreshToken.update({ where: { id: stored.id }, data: { revokedAt: new Date() } });
    return this.generateTokens(stored.userId);
  }

  async logout(refreshToken: string) {
    await prisma.refreshToken.updateMany({
      where: { token: refreshToken },
      data: { revokedAt: new Date() },
    });
  }

  async getMe(userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new AppError("User not found", 404);
    const { passwordHash: _ph, ...safeUser } = user;
    return safeUser;
  }

  private async generateTokens(userId: string) {
    const accessToken = jwt.sign({ sub: userId }, env.JWT_ACCESS_SECRET, {
      expiresIn: env.JWT_ACCESS_EXPIRES,
    });
    const refreshToken = jwt.sign({ sub: userId }, env.JWT_REFRESH_SECRET, {
      expiresIn: env.JWT_REFRESH_EXPIRES,
    });
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);
    await prisma.refreshToken.create({ data: { token: refreshToken, userId, expiresAt } });
    return { accessToken, refreshToken };
  }
}

export const authService = new AuthService();
'@

# ─── auth/auth.middleware.ts ──────────────────────────────
Set-Content -Path "apps/api/src/modules/auth/auth.middleware.ts" -Value @'
import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { env } from "../../config/env";
import { prisma } from "../../config/database";
import type { UserRole } from "@prisma/client";

declare global {
  namespace Express {
    interface Request {
      user?: { id: string; email: string; role: UserRole };
    }
  }
}

export const authenticate = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Authentication required" });
    }
    const token = authHeader.slice(7);
    const payload = jwt.verify(token, env.JWT_ACCESS_SECRET) as any;
    const user = await prisma.user.findUnique({
      where: { id: payload.sub },
      select: { id: true, email: true, role: true, isActive: true },
    });
    if (!user || !user.isActive) {
      return res.status(401).json({ error: "User not found or inactive" });
    }
    req.user = user;
    next();
  } catch (err) {
    if ((err as any).name === "TokenExpiredError") {
      return res.status(401).json({ error: "Token expired", code: "TOKEN_EXPIRED" });
    }
    return res.status(401).json({ error: "Invalid token" });
  }
};

export const authorize = (...roles: UserRole[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) return res.status(401).json({ error: "Authentication required" });
    if (!roles.includes(req.user.role)) return res.status(403).json({ error: "Insufficient permissions" });
    next();
  };
};
'@

# ─── auth/auth.controller.ts ──────────────────────────────
Set-Content -Path "apps/api/src/modules/auth/auth.controller.ts" -Value @'
import { Request, Response } from "express";
import { z } from "zod";
import { authService } from "./auth.service";
import { asyncHandler } from "../../shared/utils/asyncHandler";

export class AuthController {
  register = asyncHandler(async (req: Request, res: Response) => {
    const dto = z.object({
      email: z.string().email(),
      password: z.string().min(8),
      name: z.string().min(2),
    }).parse(req.body);
    const result = await authService.register(dto);
    res.status(201).json({ success: true, data: result });
  });

  login = asyncHandler(async (req: Request, res: Response) => {
    const dto = z.object({
      email: z.string().email(),
      password: z.string().min(1),
    }).parse(req.body);
    const result = await authService.login(dto);
    res.cookie("refreshToken", result.tokens.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 30 * 24 * 60 * 60 * 1000,
    });
    res.json({ success: true, data: { user: result.user, accessToken: result.tokens.accessToken } });
  });

  refresh = asyncHandler(async (req: Request, res: Response) => {
    const token = (req as any).cookies?.refreshToken || req.body.refreshToken;
    if (!token) return res.status(401).json({ error: "Refresh token required" });
    const tokens = await authService.refreshToken(token);
    res.cookie("refreshToken", tokens.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 30 * 24 * 60 * 60 * 1000,
    });
    res.json({ success: true, data: { accessToken: tokens.accessToken } });
  });

  logout = asyncHandler(async (req: Request, res: Response) => {
    const token = (req as any).cookies?.refreshToken || req.body.refreshToken;
    if (token) await authService.logout(token);
    res.clearCookie("refreshToken");
    res.json({ success: true, message: "Logged out" });
  });

  me = asyncHandler(async (req: Request, res: Response) => {
    const user = await authService.getMe(req.user!.id);
    res.json({ success: true, data: user });
  });
}

export const authController = new AuthController();
'@

# ─── auth/auth.routes.ts ──────────────────────────────────
Set-Content -Path "apps/api/src/modules/auth/auth.routes.ts" -Value @'
import { Router } from "express";
import { authController } from "./auth.controller";
import { authenticate } from "./auth.middleware";

const router = Router();

router.post("/register", authController.register);
router.post("/login", authController.login);
router.post("/refresh", authController.refresh);
router.post("/logout", authController.logout);
router.get("/me", authenticate, authController.me);

export default router;
'@

# ─── products/product.service.ts ──────────────────────────
Set-Content -Path "apps/api/src/modules/products/product.service.ts" -Value @'
import { prisma } from "../../config/database";
import { AppError } from "../../shared/utils/AppError";
import { logger } from "../../shared/utils/logger";
import { Queue } from "bullmq";
import { redis } from "../../config/redis";

const scraperQueue = new Queue("scraper", { connection: redis });

function detectStore(url: string) {
  if (/shopee/.test(url)) return "SHOPEE";
  if (/mercadolivre|mercadolibre|mlv\.st/.test(url)) return "MERCADO_LIVRE";
  if (/amazon/.test(url)) return "AMAZON";
  if (/shein/.test(url)) return "SHEIN";
  if (/aliexpress/.test(url)) return "ALIEXPRESS";
  return "OTHER";
}

export class ProductService {
  async addProduct(dto: { affiliateUrl: string; userId: string }) {
    const { affiliateUrl, userId } = dto;
    const store = detectStore(affiliateUrl) as any;
    const existing = await prisma.product.findFirst({ where: { affiliateUrl, createdBy: userId } });
    if (existing) throw new AppError("Product already exists", 409);
    const product = await prisma.product.create({
      data: { affiliateUrl, store, status: "PENDING", createdBy: userId },
    });
    await scraperQueue.add("scrape-product", { productId: product.id, affiliateUrl }, { attempts: 3 });
    logger.info(`Product ${product.id} queued for scraping`);
    return product;
  }

  async bulkImportUrls(urls: string[], userId: string) {
    let queued = 0;
    let invalid = 0;
    const errors: string[] = [];
    for (const url of [...new Set(urls)].filter(Boolean)) {
      try {
        new URL(url);
        const store = detectStore(url) as any;
        const existing = await prisma.product.findFirst({ where: { affiliateUrl: url, createdBy: userId } });
        if (existing) continue;
        const product = await prisma.product.create({
          data: { affiliateUrl: url, store, status: "PENDING", createdBy: userId },
        });
        await scraperQueue.add("scrape-product", { productId: product.id, affiliateUrl: url }, { attempts: 3 });
        queued++;
      } catch (e: any) {
        invalid++;
        errors.push(`${url}: ${e.message}`);
      }
    }
    return { queued, invalid, errors };
  }

  async getProducts(userId: string, filters: any = {}) {
    const { store, status, search, page = 1, limit = 20 } = filters;
    const skip = (page - 1) * limit;
    const where: any = { createdBy: userId };
    if (store) where.store = store;
    if (status) where.status = status;
    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { affiliateUrl: { contains: search, mode: "insensitive" } },
      ];
    }
    const [products, total] = await Promise.all([
      prisma.product.findMany({
        where, skip, take: limit, orderBy: { createdAt: "desc" },
        include: { _count: { select: { captions: true, banners: true } } },
      }),
      prisma.product.count({ where }),
    ]);
    return { products, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } };
  }

  async getProduct(id: string, userId: string) {
    const product = await prisma.product.findFirst({
      where: { id, createdBy: userId },
      include: { captions: { orderBy: { createdAt: "desc" } }, banners: true },
    });
    if (!product) throw new AppError("Product not found", 404);
    return product;
  }

  async rescrape(id: string, userId: string) {
    const product = await prisma.product.findFirst({ where: { id, createdBy: userId } });
    if (!product) throw new AppError("Product not found", 404);
    await prisma.product.update({ where: { id }, data: { status: "PENDING", scrapeError: null, retryCount: 0 } });
    await scraperQueue.add("scrape-product", { productId: id, affiliateUrl: product.affiliateUrl }, { attempts: 3 });
  }

  async deleteProduct(id: string, userId: string) {
    const product = await prisma.product.findFirst({ where: { id, createdBy: userId } });
    if (!product) throw new AppError("Product not found", 404);
    await prisma.product.delete({ where: { id } });
  }

  async getStats(userId: string) {
    const [total, ready, pending, errors] = await Promise.all([
      prisma.product.count({ where: { createdBy: userId } }),
      prisma.product.count({ where: { createdBy: userId, status: "READY" } }),
      prisma.product.count({ where: { createdBy: userId, status: "PENDING" } }),
      prisma.product.count({ where: { createdBy: userId, status: "ERROR" } }),
    ]);
    const byStore = await prisma.product.groupBy({
      by: ["store"], where: { createdBy: userId }, _count: { id: true },
    });
    return { total, ready, pending, errors, byStore };
  }
}

export const productService = new ProductService();
'@

# ─── products/product.routes.ts ───────────────────────────
Set-Content -Path "apps/api/src/modules/products/product.routes.ts" -Value @'
import { Router, Request, Response } from "express";
import { authenticate } from "../auth/auth.middleware";
import { asyncHandler } from "../../shared/utils/asyncHandler";
import { productService } from "./product.service";
import { z } from "zod";
import multer from "multer";

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });
const router = Router();
router.use(authenticate);

router.get("/stats", asyncHandler(async (req: Request, res: Response) => {
  const stats = await productService.getStats(req.user!.id);
  res.json({ success: true, data: stats });
}));

router.get("/", asyncHandler(async (req: Request, res: Response) => {
  const query = z.object({
    store: z.string().optional(),
    status: z.string().optional(),
    search: z.string().optional(),
    page: z.coerce.number().default(1),
    limit: z.coerce.number().max(100).default(20),
  }).parse(req.query);
  const result = await productService.getProducts(req.user!.id, query as any);
  res.json({ success: true, data: result });
}));

router.get("/:id", asyncHandler(async (req: Request, res: Response) => {
  const product = await productService.getProduct(req.params.id, req.user!.id);
  res.json({ success: true, data: product });
}));

router.post("/", asyncHandler(async (req: Request, res: Response) => {
  const { affiliateUrl } = z.object({ affiliateUrl: z.string().url() }).parse(req.body);
  const product = await productService.addProduct({ affiliateUrl, userId: req.user!.id });
  res.status(201).json({ success: true, data: product });
}));

router.post("/bulk/urls", asyncHandler(async (req: Request, res: Response) => {
  const { urls } = z.object({ urls: z.array(z.string()).min(1).max(500) }).parse(req.body);
  const result = await productService.bulkImportUrls(urls, req.user!.id);
  res.json({ success: true, data: result });
}));

router.post("/bulk/csv", upload.single("file"), asyncHandler(async (req: Request, res: Response) => {
  if (!req.file) return res.status(400).json({ error: "No file uploaded" });
  const { parse } = await import("csv-parse/sync");
  const rows = parse(req.file.buffer.toString(), { columns: true, skip_empty_lines: true, trim: true });
  const urls = rows.map((r: any) => r.url || r.link || r.affiliate_url || Object.values(r)[0]).filter(Boolean);
  const result = await productService.bulkImportUrls(urls as string[], req.user!.id);
  res.json({ success: true, data: result });
}));

router.post("/:id/rescrape", asyncHandler(async (req: Request, res: Response) => {
  await productService.rescrape(req.params.id, req.user!.id);
  res.json({ success: true, message: "Product queued for re-scraping" });
}));

router.delete("/:id", asyncHandler(async (req: Request, res: Response) => {
  await productService.deleteProduct(req.params.id, req.user!.id);
  res.json({ success: true, message: "Product deleted" });
}));

export default router;
'@

# ─── ai/ai.routes.ts ──────────────────────────────────────
Set-Content -Path "apps/api/src/modules/ai/ai.routes.ts" -Value @'
import { Router, Request, Response } from "express";
import { authenticate } from "../auth/auth.middleware";
import { asyncHandler } from "../../shared/utils/asyncHandler";
import { z } from "zod";
import OpenAI from "openai";
import { prisma } from "../../config/database";
import { AppError } from "../../shared/utils/AppError";
import { env } from "../../config/env";

const router = Router();
router.use(authenticate);
const openai = new OpenAI({ apiKey: env.OPENAI_API_KEY });

const STYLES: Record<string, string> = {
  URGENCY: "Crie legenda com URGENCIA e ESCASSEZ. Use frases como: Acabando!, So hoje!, Ultimas unidades. Tom apressado e animado.",
  DISCOUNT: "Foco no DESCONTO. Destaque a economia em reais e percentual. Compare preco original vs atual. Use: Economize, De X por Y.",
  CASUAL: "Tom CASUAL como amigo dando dica boa. Linguagem informal do dia a dia. Parece dica de amigo, nao propaganda.",
  PREMIUM: "Posicione como produto PREMIUM. Foque em qualidade e status. Tom elegante e aspiracional.",
  FLASH_SALE: "FLASH SALE com maxima urgencia! Use CAPS em palavras chave. Muitos emojis chamativos como fogo e raio.",
  VIRAL: "Estilo VIRAL. Crie curiosidade irresistivel. Faca pessoa querer marcar alguem nos comentarios.",
  INFORMATIVE: "Tom INFORMATIVO. Explique beneficios e caracteristicas principais. Ideal para produtos tecnicos.",
  EMOTIONAL: "Tom EMOCIONAL. Conecte o produto a uma emocao ou situacao. Faz pessoa se imaginar usando.",
};

router.post("/generate", asyncHandler(async (req: Request, res: Response) => {
  const { productId, styles = ["URGENCY", "DISCOUNT", "CASUAL", "VIRAL"], count = 2 } = z.object({
    productId: z.string(),
    styles: z.array(z.string()).optional(),
    count: z.number().min(1).max(5).optional(),
  }).parse(req.body);

  const product = await prisma.product.findFirst({ where: { id: productId, createdBy: req.user!.id } });
  if (!product) throw new AppError("Product not found", 404);
  if (product.status !== "READY") throw new AppError("Product not ready yet", 400);

  const context = [
    `Nome: ${product.title}`,
    `Loja: ${product.store}`,
    `Preco atual: R$ ${product.price}`,
    product.originalPrice ? `Preco original: R$ ${product.originalPrice}` : "",
    product.discountPercent ? `Desconto: ${product.discountPercent}%` : "",
    product.isFreeShipping ? "Frete: GRATIS" : "",
    product.couponCode ? `Cupom: ${product.couponCode}` : "",
    product.rating ? `Avaliacao: ${product.rating}/5` : "",
  ].filter(Boolean).join("\n");

  const results = [];
  for (const style of styles as string[]) {
    const response = await openai.chat.completions.create({
      model: env.OPENAI_MODEL,
      max_tokens: 1000,
      temperature: 0.9,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: 'Voce e especialista em marketing de afiliados brasileiro para WhatsApp. Responda SEMPRE em JSON valido: {"captions": [{"content": "texto", "emojis": ["emoji"], "hashtags": ["#tag"], "callToAction": "texto cta"}]}'
        },
        {
          role: "user",
          content: `${STYLES[style] || ""}\n\nPRODUTO:\n${context}\n\nGere ${count} legendas DIFERENTES e UNICAS em portugues brasileiro informal. Nunca repita.`
        },
      ],
    });

    const parsed = JSON.parse(response.choices[0]?.message?.content || '{"captions":[]}');
    for (const caption of parsed.captions || []) {
      const saved = await prisma.caption.create({
        data: {
          productId,
          style: style as any,
          content: caption.content,
          emojis: caption.emojis || [],
          hashtags: caption.hashtags || [],
          callToAction: caption.callToAction,
          language: "pt-BR",
        },
      });
      results.push(saved);
    }
  }
  res.json({ success: true, data: results });
}));

router.get("/best-times", asyncHandler(async (_req: Request, res: Response) => {
  res.json({
    success: true,
    data: [
      { hour: 8, label: "08:00", reason: "Manha cedo - alta atividade" },
      { hour: 12, label: "12:00", reason: "Horario do almoco" },
      { hour: 18, label: "18:00", reason: "Fim do expediente" },
      { hour: 20, label: "20:00", reason: "Pico de uso noturno" },
    ],
  });
}));

export default router;
'@

# ─── analytics/analytics.routes.ts ───────────────────────
Set-Content -Path "apps/api/src/modules/analytics/analytics.routes.ts" -Value @'
import { Router, Request, Response } from "express";
import { authenticate } from "../auth/auth.middleware";
import { asyncHandler } from "../../shared/utils/asyncHandler";
import { prisma } from "../../config/database";

const router = Router();
router.use(authenticate);

router.get("/summary", asyncHandler(async (req: Request, res: Response) => {
  const userId = req.user!.id;
  const [totalProducts, readyProducts, totalPosts, sentPosts, pendingPosts] = await Promise.all([
    prisma.product.count({ where: { createdBy: userId } }),
    prisma.product.count({ where: { createdBy: userId, status: "READY" } }),
    prisma.post.count({ where: { product: { createdBy: userId } } }),
    prisma.post.count({ where: { product: { createdBy: userId }, status: "SENT" } }),
    prisma.post.count({ where: { product: { createdBy: userId }, status: { in: ["QUEUED", "APPROVED"] } } }),
  ]);
  res.json({
    success: true,
    data: {
      products: { total: totalProducts, ready: readyProducts },
      posts: { total: totalPosts, sent: sentPosts, pending: pendingPosts },
      clicks: { today: 0, week: 0, month: 0 },
      conversions: { week: 0, rate: "0.00" },
      revenue: { week: 0 },
    },
  });
}));

router.get("/clicks", asyncHandler(async (req: Request, res: Response) => {
  const days = parseInt(req.query.days as string) || 30;
  const data = Array.from({ length: days }, (_, i) => {
    const d = new Date(Date.now() - (days - 1 - i) * 24 * 60 * 60 * 1000);
    return { date: d.toISOString().split("T")[0], clicks: 0 };
  });
  res.json({ success: true, data });
}));

router.get("/top-products", asyncHandler(async (req: Request, res: Response) => {
  const limit = parseInt(req.query.limit as string) || 10;
  const products = await prisma.product.findMany({
    where: { createdBy: req.user!.id, status: "READY" },
    orderBy: { clickCount: "desc" },
    take: limit,
    select: { id: true, title: true, store: true, price: true, discountPercent: true, primaryImageUrl: true, clickCount: true, conversionCount: true },
  });
  res.json({ success: true, data: products.map(p => ({ ...p, conversionRate: "0.0" })) });
}));

router.get("/stores", asyncHandler(async (req: Request, res: Response) => {
  const data = await prisma.product.groupBy({
    by: ["store"],
    where: { createdBy: req.user!.id },
    _count: { id: true },
    _sum: { clickCount: true },
  });
  res.json({ success: true, data: data.map(s => ({ store: s.store, products: s._count.id, clicks: s._sum.clickCount || 0 })) });
}));

export default router;
'@

# ─── whatsapp/whatsapp.routes.ts ──────────────────────────
Set-Content -Path "apps/api/src/modules/whatsapp/whatsapp.routes.ts" -Value @'
import { Router, Request, Response } from "express";
import { authenticate } from "../auth/auth.middleware";
import { asyncHandler } from "../../shared/utils/asyncHandler";
import { prisma } from "../../config/database";

const router = Router();
router.use(authenticate);

router.get("/status", asyncHandler(async (_req: Request, res: Response) => {
  res.json({ success: true, data: { connected: false, message: "Configure Evolution API no .env" } });
}));

router.get("/groups", asyncHandler(async (_req: Request, res: Response) => {
  const groups = await prisma.whatsAppGroup.findMany({ orderBy: { name: "asc" } });
  res.json({ success: true, data: groups });
}));

router.post("/sync-groups", asyncHandler(async (_req: Request, res: Response) => {
  res.json({ success: true, data: { synced: 0, message: "Configure o WhatsApp primeiro no .env" } });
}));

export default router;
'@

# ─── scheduler/scheduler.routes.ts ───────────────────────
Set-Content -Path "apps/api/src/modules/scheduler/scheduler.routes.ts" -Value @'
import { Router, Request, Response } from "express";
import { authenticate } from "../auth/auth.middleware";
import { asyncHandler } from "../../shared/utils/asyncHandler";
import { prisma } from "../../config/database";
import { AppError } from "../../shared/utils/AppError";
import { z } from "zod";

const router = Router();
router.use(authenticate);

router.get("/queue", asyncHandler(async (req: Request, res: Response) => {
  const posts = await prisma.post.findMany({
    where: { product: { createdBy: req.user!.id } },
    include: {
      product: { select: { title: true, store: true, primaryImageUrl: true, price: true } },
      caption: { select: { style: true, content: true } },
      group: { select: { name: true } },
    },
    orderBy: { scheduledAt: "asc" },
    take: 100,
  });
  res.json({ success: true, data: posts });
}));

router.post("/quick", asyncHandler(async (req: Request, res: Response) => {
  const { productId, groupIds, postAt, captionId, bannerId } = z.object({
    productId: z.string(),
    groupIds: z.array(z.string()).min(1),
    postAt: z.string(),
    captionId: z.string().optional(),
    bannerId: z.string().optional(),
  }).parse(req.body);

  const product = await prisma.product.findFirst({
    where: { id: productId, createdBy: req.user!.id },
    include: { captions: { take: 1 }, banners: { take: 1 } },
  });
  if (!product) throw new AppError("Product not found", 404);

  const scheduledAt = new Date(postAt);
  const posts = [];
  for (const groupId of groupIds) {
    const group = await prisma.whatsAppGroup.findFirst({ where: { id: groupId, isActive: true } });
    if (!group) continue;
    const post = await prisma.post.create({
      data: {
        productId,
        groupId,
        captionId: captionId || product.captions[0]?.id,
        bannerId: bannerId || product.banners[0]?.id,
        scheduledAt,
        status: "APPROVED",
      },
    });
    posts.push(post);
  }
  res.status(201).json({ success: true, data: posts });
}));

router.patch("/:id/cancel", asyncHandler(async (req: Request, res: Response) => {
  const post = await prisma.post.findFirst({ where: { id: req.params.id, product: { createdBy: req.user!.id } } });
  if (!post) throw new AppError("Post not found", 404);
  await prisma.post.update({ where: { id: req.params.id }, data: { status: "CANCELLED" } });
  res.json({ success: true, message: "Post cancelled" });
}));

export default router;
'@

# ─── admin/admin.routes.ts ────────────────────────────────
Set-Content -Path "apps/api/src/modules/admin/admin.routes.ts" -Value @'
import { Router, Request, Response } from "express";
import { authenticate, authorize } from "../auth/auth.middleware";
import { asyncHandler } from "../../shared/utils/asyncHandler";
import { prisma } from "../../config/database";

const router = Router();
router.use(authenticate);

router.get("/users", authorize("SUPER_ADMIN", "ADMIN"), asyncHandler(async (_req: Request, res: Response) => {
  const users = await prisma.user.findMany({
    select: { id: true, email: true, name: true, role: true, isActive: true, createdAt: true },
  });
  res.json({ success: true, data: users });
}));

export default router;
'@

# ─── tracking/tracking.routes.ts ─────────────────────────
Set-Content -Path "apps/api/src/modules/tracking/tracking.routes.ts" -Value @'
import { Router, Request, Response } from "express";

const router = Router();

router.get("/:code", async (req: Request, res: Response) => {
  res.redirect(301, "https://shopee.com.br");
});

export default router;
'@

# ─── campaigns/campaign.routes.ts ────────────────────────
Set-Content -Path "apps/api/src/modules/campaigns/campaign.routes.ts" -Value @'
import { Router, Request, Response } from "express";
import { authenticate } from "../auth/auth.middleware";
import { asyncHandler } from "../../shared/utils/asyncHandler";
import { prisma } from "../../config/database";
import { z } from "zod";

const router = Router();
router.use(authenticate);

router.get("/", asyncHandler(async (req: Request, res: Response) => {
  const campaigns = await prisma.campaign.findMany({
    where: { createdBy: req.user!.id },
    include: { _count: { select: { products: true } } },
    orderBy: { createdAt: "desc" },
  });
  res.json({ success: true, data: campaigns });
}));

router.post("/", asyncHandler(async (req: Request, res: Response) => {
  const { name, description } = z.object({
    name: z.string().min(1),
    description: z.string().optional(),
  }).parse(req.body);
  const campaign = await prisma.campaign.create({ data: { name, description, createdBy: req.user!.id } });
  res.status(201).json({ success: true, data: campaign });
}));

export default router;
'@

# ─── tsconfig.json ────────────────────────────────────────
Set-Content -Path "apps/api/tsconfig.json" -Value @'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
'@

Write-Host ""
Write-Host "Todos os arquivos do backend criados com sucesso!" -ForegroundColor Green
Write-Host ""
