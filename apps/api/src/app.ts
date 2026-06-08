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
    socket.join(user:${userId});
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

app.use(/api/${env.API_VERSION}, apiRouter);
app.use("/t", trackingRoutes);
app.use((_req: Request, res: Response) => res.status(404).json({ error: "Route not found" }));
app.use(errorHandler);

export { app, httpServer };
