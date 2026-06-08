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
