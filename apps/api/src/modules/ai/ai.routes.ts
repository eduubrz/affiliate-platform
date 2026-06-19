import { Router, Request, Response } from 'express';
import { authenticate } from '../auth/auth.middleware';
import { asyncHandler } from '../../shared/utils/asyncHandler';
import { z } from 'zod';
import Groq from 'groq-sdk';
import { prisma } from '../../config/database';
import { AppError } from '../../shared/utils/AppError';
import { env } from '../../config/env';

const router = Router();
router.use(authenticate);
const groq = new Groq({ apiKey: env.OPENAI_API_KEY });

const STYLES: Record<string, string> = {
  URGENCY: 'Crie legenda com URGENCIA e ESCASSEZ. Use frases como: Acabando!, So hoje!, Ultimas unidades. Tom apressado e animado.',
  DISCOUNT: 'Foco no DESCONTO. Destaque a economia em reais e percentual. Compare preco original vs atual.',
  CASUAL: 'Tom CASUAL como amigo dando dica boa. Linguagem informal do dia a dia.',
  PREMIUM: 'Posicione como produto PREMIUM. Foque em qualidade e status. Tom elegante.',
  FLASH_SALE: 'FLASH SALE com maxima urgencia! Use CAPS em palavras chave. Muitos emojis chamativos.',
  VIRAL: 'Estilo VIRAL. Crie curiosidade irresistivel. Faca pessoa querer marcar alguem.',
  INFORMATIVE: 'Tom INFORMATIVO. Explique beneficios e caracteristicas principais.',
  EMOTIONAL: 'Tom EMOCIONAL. Conecte o produto a uma emocao ou situacao.',
};

router.post('/generate', asyncHandler(async (req: Request, res: Response) => {
  const { productId, styles = ['URGENCY', 'DISCOUNT', 'CASUAL', 'VIRAL'], count = 2 } = z.object({
    productId: z.string(),
    styles: z.array(z.string()).optional(),
    count: z.number().min(1).max(5).optional(),
  }).parse(req.body);

  const product = await prisma.product.findFirst({ where: { id: productId, createdBy: req.user!.id } });
  if (!product) throw new AppError('Product not found', 404);
  if (product.status !== 'READY') throw new AppError('Product not ready yet', 400);

  const context = [
    'Nome: ' + product.title,
    'Loja: ' + product.store,
    'Preco atual: R$ ' + product.price,
    product.originalPrice ? 'Preco original: R$ ' + product.originalPrice : '',
    product.discountPercent ? 'Desconto: ' + product.discountPercent + '%' : '',
    product.isFreeShipping ? 'Frete: GRATIS' : '',
    product.couponCode ? 'Cupom: ' + product.couponCode : '',
    product.rating ? 'Avaliacao: ' + product.rating + '/5' : '',
  ].filter(Boolean).join('\n');

  const results = [];
  for (const style of styles as string[]) {
    const response = await groq.chat.completions.create({
      model: env.OPENAI_MODEL,
      max_tokens: 1000,
      temperature: 0.9,
      messages: [
        {
          role: 'system',
          content: 'Voce e especialista em marketing de afiliados brasileiro para WhatsApp. Responda APENAS em JSON valido sem markdown: {"captions": [{"content": "texto", "emojis": ["emoji"], "hashtags": ["#tag"], "callToAction": "texto cta"}]}'
        },
        {
          role: 'user',
          content: (STYLES[style] || '') + '\n\nPRODUTO:\n' + context + '\n\nGere ' + count + ' legendas DIFERENTES em portugues brasileiro informal.'
        },
      ],
    });

    try {
      const raw = response.choices[0]?.message?.content || '{"captions":[]}';
      const parsed = JSON.parse(raw);
      for (const caption of parsed.captions || []) {
        const saved = await prisma.caption.create({
          data: {
            productId,
            style: style as any,
            content: caption.content,
            emojis: caption.emojis || [],
            hashtags: caption.hashtags || [],
            callToAction: caption.callToAction,
            language: 'pt-BR',
          },
        });
        results.push(saved);
      }
    } catch (e) {
      console.error('Parse error:', e);
    }
  }
  res.json({ success: true, data: results });
}));

router.get('/best-times', asyncHandler(async (_req: Request, res: Response) => {
  res.json({
    success: true,
    data: [
      { hour: 8, label: '08:00', reason: 'Manha cedo' },
      { hour: 12, label: '12:00', reason: 'Almoco' },
      { hour: 18, label: '18:00', reason: 'Fim do expediente' },
      { hour: 20, label: '20:00', reason: 'Pico noturno' },
    ],
  });
}));

export default router;
