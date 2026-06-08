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
