# AffiliateOS — Plataforma de Automacao de Marketing de Afiliados

## Instalacao rapida

1. Copie o .env: `cp apps/api/.env.example apps/api/.env`
2. Preencha a OPENAI_API_KEY no .env
3. Suba os servicos: `docker-compose up -d`
4. Rode as migrations: `docker-compose exec api npx prisma migrate deploy`
5. Acesse: http://localhost:3000

Veja INSTALLATION.md para o guia completo.