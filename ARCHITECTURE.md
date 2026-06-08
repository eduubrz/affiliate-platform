# Affiliate Marketing Automation Platform — Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                          │
│   Next.js 14 (App Router) + React + TypeScript + Tailwind    │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTPS / REST / WebSocket
┌─────────────────────▼───────────────────────────────────────┐
│                      API GATEWAY (Nginx)                      │
│              Rate Limiting · Auth · Routing                   │
└──────┬──────────────┬──────────────┬────────────────────────┘
       │              │              │
┌──────▼──────┐ ┌─────▼──────┐ ┌────▼──────────┐
│  Auth API   │ │  Core API  │ │ Analytics API  │
│  Node/TS    │ │  Node/TS   │ │   Node/TS      │
└──────┬──────┘ └─────┬──────┘ └────┬──────────┘
       │              │              │
┌──────▼──────────────▼──────────────▼──────────┐
│               PostgreSQL (Primary DB)           │
│         Redis (Cache + Queue + Sessions)        │
└────────────────────┬───────────────────────────┘
                     │
┌────────────────────▼───────────────────────────┐
│              WORKER SERVICES                    │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ Scraper Worker│  │  AI Worker   │            │
│  │ (BullMQ)     │  │  (BullMQ)    │            │
│  └──────────────┘  └──────────────┘            │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ Image Worker │  │ Scheduler    │            │
│  │ (Sharp/Canvas)│  │  Worker      │            │
│  └──────────────┘  └──────────────┘            │
└────────────────────────────────────────────────┘
```

## Folder Structure

```
affiliate-platform/
├── apps/
│   ├── web/                    # Next.js 14 frontend
│   │   ├── app/
│   │   │   ├── (auth)/
│   │   │   │   ├── login/
│   │   │   │   └── register/
│   │   │   ├── (dashboard)/
│   │   │   │   ├── layout.tsx
│   │   │   │   ├── page.tsx          # Dashboard home
│   │   │   │   ├── products/
│   │   │   │   ├── campaigns/
│   │   │   │   ├── scheduler/
│   │   │   │   ├── analytics/
│   │   │   │   ├── whatsapp/
│   │   │   │   └── settings/
│   │   │   └── api/                  # Next.js API routes (proxy)
│   │   ├── components/
│   │   │   ├── ui/                   # Base UI components
│   │   │   ├── dashboard/
│   │   │   ├── products/
│   │   │   ├── analytics/
│   │   │   └── shared/
│   │   ├── lib/
│   │   │   ├── api.ts
│   │   │   ├── auth.ts
│   │   │   └── utils.ts
│   │   └── public/
│   │
│   └── api/                    # Express backend
│       ├── src/
│       │   ├── config/
│       │   │   ├── database.ts
│       │   │   ├── redis.ts
│       │   │   └── env.ts
│       │   ├── modules/
│       │   │   ├── auth/
│       │   │   │   ├── auth.controller.ts
│       │   │   │   ├── auth.service.ts
│       │   │   │   ├── auth.routes.ts
│       │   │   │   └── auth.middleware.ts
│       │   │   ├── products/
│       │   │   │   ├── product.controller.ts
│       │   │   │   ├── product.service.ts
│       │   │   │   ├── product.routes.ts
│       │   │   │   └── scrapers/
│       │   │   │       ├── base.scraper.ts
│       │   │   │       ├── shopee.scraper.ts
│       │   │   │       ├── mercadolivre.scraper.ts
│       │   │   │       ├── amazon.scraper.ts
│       │   │   │       ├── shein.scraper.ts
│       │   │   │       └── aliexpress.scraper.ts
│       │   │   ├── ai/
│       │   │   │   ├── ai.controller.ts
│       │   │   │   ├── ai.service.ts
│       │   │   │   └── templates/
│       │   │   ├── campaigns/
│       │   │   ├── scheduler/
│       │   │   ├── whatsapp/
│       │   │   ├── analytics/
│       │   │   └── admin/
│       │   ├── workers/
│       │   │   ├── scraper.worker.ts
│       │   │   ├── ai.worker.ts
│       │   │   ├── image.worker.ts
│       │   │   └── scheduler.worker.ts
│       │   ├── shared/
│       │   │   ├── middleware/
│       │   │   ├── utils/
│       │   │   └── types/
│       │   └── app.ts
│       └── Dockerfile
│
├── packages/
│   └── shared/                 # Shared types/utils
│       └── src/
│           ├── types/
│           └── constants/
│
├── infra/
│   ├── docker-compose.yml
│   ├── docker-compose.prod.yml
│   ├── nginx/
│   │   └── nginx.conf
│   └── scripts/
│       ├── setup.sh
│       └── deploy.sh
│
└── docs/
    ├── API.md
    └── DEPLOYMENT.md
```

## Database Schema (PostgreSQL)

### Tables

- **users** — authentication, roles, settings
- **products** — scraped product data from all stores
- **affiliate_links** — raw affiliate URLs + metadata
- **captions** — AI-generated captions per product
- **banners** — generated promotional images
- **campaigns** — grouped products for promotion
- **schedules** — when/where to post
- **whatsapp_groups** — connected WA groups
- **posts** — execution log per scheduled post
- **analytics_events** — clicks, conversions, revenue
- **audit_logs** — admin tracking

## Technology Decisions

|Layer     |Choice                     |Why                               |
|----------|---------------------------|----------------------------------|
|Frontend  |Next.js 14 App Router      |SSR, streaming, server actions    |
|Styling   |Tailwind CSS               |Rapid UI, consistent design tokens|
|Backend   |Express + TypeScript       |Mature, fast, ecosystem           |
|Queue     |BullMQ + Redis             |Reliable job processing           |
|ORM       |Prisma                     |Type-safe DB access               |
|AI        |OpenAI GPT-4o              |Best caption quality              |
|Images    |Sharp + Canvas             |Fast server-side processing       |
|Auth      |JWT + Refresh tokens       |Stateless, scalable               |
|Storage   |S3-compatible (MinIO local)|Image storage                     |
|Monitoring|Winston + Sentry           |Production logging                |