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
