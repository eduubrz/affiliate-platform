import { Worker, Job, Queue } from 'bullmq';
import { redis } from '../config/redis';
import { prisma } from '../config/database';
import { logger } from '../shared/utils/logger';

export const scraperQueue = new Queue('scraper', { connection: redis });
export const aiQueue = new Queue('ai-generation', { connection: redis });

async function scrapeProduct(url: string) {
  const response = await fetch(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' },
    redirect: 'follow',
  });

  if (!response.ok) throw new Error('Failed to fetch: ' + response.status);
  const html = await response.text();

  // Shopee
  if (/shopee/.test(url)) {
    const match = url.match(/\.(\d+)\.(\d+)/);
    if (match) {
      const [, shopId, itemId] = match;
      const apiUrl = 'https://shopee.com.br/api/v4/item/get?itemid=' + itemId + '&shopid=' + shopId;
      const res = await fetch(apiUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      const data = await res.json();
      const item = data?.data?.item;
      if (item) {
        return {
          title: item.name,
          price: item.price / 100000,
          originalPrice: item.price_before_discount ? item.price_before_discount / 100000 : null,
          discountPercent: item.raw_discount || null,
          imageUrls: (item.images || []).map((img: string) => 'https://cf.shopee.com.br/file/' + img),
          primaryImageUrl: item.images?.[0] ? 'https://cf.shopee.com.br/file/' + item.images[0] : null,
          isFreeShipping: item.show_free_shipping || false,
          rating: item.item_rating?.rating_star || null,
          reviewCount: item.item_rating?.rating_count?.[0] || null,
          soldCount: item.historical_sold || null,
        };
      }
    }
  }

  // Mercado Livre
  if (/mercadolivre|mercadolibre/.test(url)) {
    const idMatch = url.match(/MLB-?(\d+)/i);
    if (idMatch) {
      const itemId = 'MLB' + idMatch[1];
      const res = await fetch('https://api.mercadolibre.com/items/' + itemId);
      const item = await res.json();
      return {
        title: item.title,
        price: item.price,
        originalPrice: item.original_price || null,
        discountPercent: item.original_price ? Math.round((1 - item.price / item.original_price) * 100) : null,
        imageUrls: (item.pictures || []).map((p: any) => p.url),
        primaryImageUrl: item.pictures?.[0]?.url || null,
        isFreeShipping: item.shipping?.free_shipping || false,
        rating: null,
        reviewCount: null,
        soldCount: item.sold_quantity || null,
      };
    }
  }

  // Fallback: tenta extrair meta tags
  const titleMatch = html.match(/<meta property="og:title" content="([^"]+)"/i);
  const imageMatch = html.match(/<meta property="og:image" content="([^"]+)"/i);
  const priceMatch = html.match(/<meta property="product:price:amount" content="([^"]+)"/i);

  return {
    title: titleMatch?.[1] || 'Produto',
    price: priceMatch ? parseFloat(priceMatch[1]) : null,
    originalPrice: null,
    discountPercent: null,
    imageUrls: imageMatch ? [imageMatch[1]] : [],
    primaryImageUrl: imageMatch?.[1] || null,
    isFreeShipping: false,
    rating: null,
    reviewCount: null,
    soldCount: null,
  };
}

export const scraperWorker = new Worker(
  'scraper',
  async (job: Job) => {
    const { productId, affiliateUrl } = job.data;
    logger.info('[Scraper] Processing: ' + affiliateUrl);

    const product = await prisma.product.findUnique({ where: { id: productId } });
    if (!product) return;

    await prisma.product.update({ where: { id: productId }, data: { status: 'SCRAPING' } });

    try {
      const scraped = await scrapeProduct(affiliateUrl);

      await prisma.product.update({
        where: { id: productId },
        data: {
          title: scraped.title,
          price: scraped.price,
          originalPrice: scraped.originalPrice,
          discountPercent: scraped.discountPercent,
          imageUrls: scraped.imageUrls,
          primaryImageUrl: scraped.primaryImageUrl,
          isFreeShipping: scraped.isFreeShipping,
          rating: scraped.rating,
          reviewCount: scraped.reviewCount,
          soldCount: scraped.soldCount,
          status: 'READY',
          scrapedAt: new Date(),
          scrapeError: null,
        },
      });

      logger.info('[Scraper] Done: ' + scraped.title);

      await aiQueue.add('generate-captions', {
        productId,
        userId: product.createdBy,
        styles: ['URGENCY', 'DISCOUNT', 'CASUAL', 'VIRAL'],
        count: 2,
      });

    } catch (error: any) {
      logger.error('[Scraper] Error: ' + error.message);
      await prisma.product.update({
        where: { id: productId },
        data: { status: 'ERROR', scrapeError: error.message },
      });
    }
  },
  { connection: redis, concurrency: 3 }
);

scraperWorker.on('completed', (job) => logger.info('[Scraper] Job ' + job.id + ' completed'));
scraperWorker.on('failed', (job, err) => logger.error('[Scraper] Job ' + job?.id + ' failed: ' + err.message));
