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
