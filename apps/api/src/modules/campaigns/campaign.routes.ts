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
