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
