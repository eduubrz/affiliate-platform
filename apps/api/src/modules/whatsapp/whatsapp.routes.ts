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
