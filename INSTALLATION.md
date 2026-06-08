# 🚀 AffiliateOS — Guia Completo de Instalação e Deploy

-----

## Pré-requisitos

- **Docker** e **Docker Compose** instalados
- **Node.js 20+** (para desenvolvimento local)
- **Git**
- Chave de API da **OpenAI** (para geração de legendas)

-----

## 1. Clonar e Configurar

```bash
# Clonar o repositório
git clone https://github.com/seu-usuario/affiliate-platform.git
cd affiliate-platform

# Copiar e editar variáveis de ambiente da API
cp apps/api/.env.example apps/api/.env
```

Edite `apps/api/.env` e preencha pelo menos:

```
OPENAI_API_KEY=sk-...         # OBRIGATÓRIO para IA
JWT_ACCESS_SECRET=...         # Troque para string aleatória forte (32+ chars)
JWT_REFRESH_SECRET=...        # Troque para string aleatória forte (32+ chars)
```

-----

## 2. Subir com Docker Compose (modo dev)

```bash
# Subir todos os serviços
docker-compose up -d

# Verificar status
docker-compose ps

# Ver logs da API
docker-compose logs -f api

# Ver logs de todos
docker-compose logs -f
```

Isso sobe automaticamente:

- ✅ PostgreSQL na porta 5432
- ✅ Redis na porta 6379
- ✅ MinIO (storage) na porta 9000 / console 9001
- ✅ API (Express) na porta 4000
- ✅ Frontend (Next.js) na porta 3000
- ✅ Evolution API (WhatsApp) na porta 8080

-----

## 3. Rodar as Migrations do Banco

```bash
# Entrar no container da API
docker-compose exec api sh

# Rodar migrations
npx prisma migrate deploy

# (Opcional) Criar usuário admin inicial
npx tsx src/seed.ts

# Sair do container
exit
```

-----

## 4. Configurar WhatsApp (Evolution API)

### 4.1. Conectar número

```bash
# 1. Acesse http://localhost:8080 (Evolution API)
# 2. Ou use a API diretamente:

curl -X POST http://localhost:8080/instance/create \
  -H "apikey: your-evolution-api-key-change-this" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "affiliate-bot", "integration": "WHATSAPP-BAILEYS"}'
```

### 4.2. Escanear QR Code

No dashboard: vá em **WhatsApp → Status → QR Code** e escaneie com seu celular.

### 4.3. Sincronizar grupos

No dashboard: **WhatsApp → Sincronizar Grupos**

-----

## 5. Acesso

|Serviço      |URL                    |Credenciais              |
|-------------|-----------------------|-------------------------|
|Frontend     |<http://localhost:3000>|Email e senha cadastrados|
|API          |<http://localhost:4000>|—                        |
|MinIO Console|<http://localhost:9001>|minioadmin / minioadmin  |
|Evolution API|<http://localhost:8080>|—                        |

-----

## 6. Deploy em Produção (VPS)

### 6.1. Preparar servidor (Ubuntu 22.04)

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 6.2. Configurar domínio e SSL

```bash
# Instalar Certbot
sudo apt install certbot -y

# Gerar certificado SSL
sudo certbot certonly --standalone -d seudominio.com.br -d api.seudominio.com.br
```

### 6.3. Deploy

```bash
# Clonar no servidor
git clone https://github.com/seu-usuario/affiliate-platform.git
cd affiliate-platform

# Configurar .env de produção
cp apps/api/.env.example apps/api/.env
nano apps/api/.env  # Preencher com valores de produção

# Subir com perfil de produção (inclui Nginx)
docker-compose --profile production up -d

# Rodar migrations
docker-compose exec api npx prisma migrate deploy
```

-----

## 7. Deploy no Railway

```bash
# Instalar Railway CLI
npm install -g @railway/cli

# Login
railway login

# Inicializar projeto
railway init

# Adicionar serviços
railway add postgresql
railway add redis

# Deploy da API
cd apps/api
railway up

# Deploy do Frontend
cd apps/web
railway up
```

Variáveis de ambiente Railway:

- Adicione via dashboard ou `railway variables set KEY=VALUE`

-----

## 8. Deploy no Render

1. Conecte seu GitHub no **Render**
1. Crie um **Web Service** apontando para `apps/api`
1. Configure as variáveis de ambiente
1. Crie um **PostgreSQL** e **Redis** no Render
1. Deploy automático a cada push

-----

## 9. Usar a Plataforma

### Fluxo básico:

```
1. Adicionar produto (URL de afiliado)
      ↓
2. Sistema scrapa automaticamente (título, preço, imagem)
      ↓
3. IA gera legendas (8 estilos diferentes)
      ↓
4. Sistema gera banners (3 formatos)
      ↓
5. Agendar publicação nos grupos
      ↓
6. Post enviado automaticamente no horário
      ↓
7. Analytics registra cliques e conversões
```

### Importação em massa:

- **CSV**: Uma URL por linha com coluna `url` ou `link`
- **Excel**: Mesma estrutura em .xlsx
- **URLs diretas**: Cole várias URLs no campo de texto

### Agendamento automático:

```
Dashboard → Agendamentos → Distribuição Automática
→ Selecionar produtos
→ Selecionar grupo(s)
→ Definir horário de início e fim
→ Sistema distribui posts ao longo do dia
```

-----

## 10. Troubleshooting

### API não inicia

```bash
docker-compose logs api
# Verificar se .env está correto
# Verificar se postgres está rodando: docker-compose ps
```

### Scraping falhando

```bash
# Ver jobs na fila
docker-compose exec redis redis-cli LLEN bull:scraper:wait

# Verificar logs dos workers
docker-compose logs api | grep ScraperWorker
```

### WhatsApp desconectado

```bash
# Reconectar instância
curl -X DELETE http://localhost:8080/instance/logout/affiliate-bot \
  -H "apikey: your-evolution-api-key"
# Depois escanear QR Code novamente
```

-----

## 11. Variáveis de Ambiente (Produção)

```bash
# Gerar secrets fortes
openssl rand -hex 32   # Para JWT secrets
openssl rand -hex 16   # Para ENCRYPTION_KEY
```

Valores MÍNIMOS obrigatórios para produção:

```env
NODE_ENV=production
DATABASE_URL=...
REDIS_URL=...
JWT_ACCESS_SECRET=<32+ chars aleatórios>
JWT_REFRESH_SECRET=<32+ chars aleatórios>
OPENAI_API_KEY=sk-...
FRONTEND_URL=https://seudominio.com.br
TRACKING_BASE_URL=https://seudominio.com.br/t
STORAGE_ENDPOINT=...
STORAGE_ACCESS_KEY=...
STORAGE_SECRET_KEY=...
STORAGE_BUCKET=affiliate-banners
STORAGE_PUBLIC_URL=...
```

-----

## 12. Roadmap de Melhorias

### Curto prazo

- [ ] Integração nativa Shopee Affiliate API
- [ ] Link tracker com domínio próprio (ex: vai.br/abc123)
- [ ] Geração de vídeos curtos (Reels/Stories)
- [ ] App mobile (React Native)

### Médio prazo

- [ ] Multi-usuário (times e agências)
- [ ] Telegram support
- [ ] Instagram Direct support
- [ ] A/B testing automático de legendas
- [ ] Detecção automática de promoções relâmpago

### Longo prazo

- [ ] Modelo de IA próprio treinado em dados de afiliados BR
- [ ] Integração com Hotmart e outros infoprodutos
- [ ] API pública para integrações externas
- [ ] SaaS multi-tenant com billing