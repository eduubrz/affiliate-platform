# ============================================================
# setup-frontend.ps1 — Cria todos os arquivos do frontend
# ============================================================

Write-Host "Criando arquivos do frontend..." -ForegroundColor Cyan

# ─── next.config.js ───────────────────────────────────────
Set-Content -Path "apps/web/next.config.js" -Value @'
/** @type {import("next").NextConfig} */
const nextConfig = {
  images: {
    domains: [
      "localhost",
      "cf.shopee.com.br",
      "http2.mlstatic.com",
      "m.media-amazon.com",
      "img.ltwebstatic.com",
    ],
  },
};
module.exports = nextConfig;
'@

# ─── tailwind.config.js ───────────────────────────────────
Set-Content -Path "apps/web/tailwind.config.js" -Value @'
/** @type {import("tailwindcss").Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
    "./lib/**/*.{js,ts,jsx,tsx}",
  ],
  theme: { extend: {} },
  plugins: [],
};
'@

# ─── postcss.config.js ────────────────────────────────────
Set-Content -Path "apps/web/postcss.config.js" -Value @'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
'@

# ─── tsconfig.json ────────────────────────────────────────
Set-Content -Path "apps/web/tsconfig.json" -Value @'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
'@

# ─── app/globals.css ──────────────────────────────────────
Set-Content -Path "apps/web/app/globals.css" -Value @'
@tailwind base;
@tailwind components;
@tailwind utilities;

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html {
  scroll-behavior: smooth;
}

::-webkit-scrollbar {
  width: 6px;
}

::-webkit-scrollbar-track {
  background: transparent;
}

::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 3px;
}
'@

# ─── app/layout.tsx ───────────────────────────────────────
Set-Content -Path "apps/web/app/layout.tsx" -Value @'
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { Toaster } from "react-hot-toast";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "AffiliateOS — Automacao de Marketing de Afiliados",
  description: "Plataforma completa para automacao de marketing de afiliados no WhatsApp",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR">
      <body className={`${inter.className} bg-[#0A0A0F] text-white antialiased`}>
        {children}
        <Toaster
          position="top-right"
          toastOptions={{
            style: {
              background: "#1a1a25",
              color: "#fff",
              border: "1px solid rgba(255,255,255,0.1)",
              borderRadius: "10px",
              fontSize: "14px",
            },
          }}
        />
      </body>
    </html>
  );
}
'@

# ─── app/page.tsx (redirect) ──────────────────────────────
Set-Content -Path "apps/web/app/page.tsx" -Value @'
import { redirect } from "next/navigation";

export default function Home() {
  redirect("/login");
}
'@

# ─── app/login/page.tsx ───────────────────────────────────
New-Item -ItemType Directory -Force -Path "apps/web/app/login" | Out-Null
Set-Content -Path "apps/web/app/login/page.tsx" -Value @'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Erro ao fazer login");
      localStorage.setItem("accessToken", data.data.accessToken);
      localStorage.setItem("user", JSON.stringify(data.data.user));
      router.push("/dashboard");
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-[#0A0A0F] flex items-center justify-center p-4">
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-violet-500/5 rounded-full blur-[120px]" />
      </div>
      <div className="relative w-full max-w-sm">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-gradient-to-br from-violet-500 to-fuchsia-500 mb-4 text-2xl">
            ⚡
          </div>
          <h1 className="text-2xl font-bold text-white">AffiliateOS</h1>
          <p className="text-white/40 text-sm mt-1">Automacao de marketing de afiliados</p>
        </div>
        <form onSubmit={handleSubmit} className="bg-[#111118] border border-white/5 rounded-2xl p-6 space-y-4">
          <div>
            <label className="block text-sm text-white/60 mb-2">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full bg-[#0A0A0F] border border-white/10 rounded-lg px-4 py-2.5 text-sm text-white placeholder-white/20 focus:outline-none focus:border-violet-500/50"
              placeholder="seu@email.com"
            />
          </div>
          <div>
            <label className="block text-sm text-white/60 mb-2">Senha</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full bg-[#0A0A0F] border border-white/10 rounded-lg px-4 py-2.5 text-sm text-white placeholder-white/20 focus:outline-none focus:border-violet-500/50"
              placeholder="••••••••"
            />
          </div>
          {error && (
            <div className="bg-red-500/10 border border-red-500/20 rounded-lg px-4 py-2.5 text-sm text-red-400">
              {error}
            </div>
          )}
          <button
            type="submit"
            disabled={loading}
            className="w-full py-2.5 rounded-lg bg-gradient-to-r from-violet-500 to-fuchsia-500 hover:from-violet-400 hover:to-fuchsia-400 text-sm font-semibold text-white disabled:opacity-60 transition-all"
          >
            {loading ? "Entrando..." : "Entrar"}
          </button>
        </form>
      </div>
    </div>
  );
}
'@

# ─── app/dashboard/layout.tsx ─────────────────────────────
New-Item -ItemType Directory -Force -Path "apps/web/app/dashboard" | Out-Null
Set-Content -Path "apps/web/app/dashboard/layout.tsx" -Value @'
"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

const NAV = [
  { href: "/dashboard", icon: "📊", label: "Dashboard" },
  { href: "/dashboard/products", icon: "📦", label: "Produtos" },
  { href: "/dashboard/scheduler", icon: "📅", label: "Agendamentos" },
  { href: "/dashboard/whatsapp", icon: "💬", label: "WhatsApp" },
  { href: "/dashboard/analytics", icon: "📈", label: "Analytics" },
  { href: "/dashboard/settings", icon: "⚙️", label: "Configuracoes" },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [user, setUser] = useState<any>(null);
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    const stored = localStorage.getItem("user");
    if (!stored) { router.push("/login"); return; }
    setUser(JSON.parse(stored));
  }, []);

  function logout() {
    localStorage.removeItem("accessToken");
    localStorage.removeItem("user");
    router.push("/login");
  }

  return (
    <div className="flex h-screen bg-[#0A0A0F] text-white overflow-hidden">
      {/* Sidebar */}
      <aside className={`
        fixed inset-y-0 left-0 z-50 w-64 flex flex-col
        bg-[#111118] border-r border-white/5
        transform transition-transform duration-300
        ${sidebarOpen ? "translate-x-0" : "-translate-x-full"}
        lg:relative lg:translate-x-0
      `}>
        <div className="flex items-center gap-3 px-6 py-5 border-b border-white/5">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-violet-500 to-fuchsia-500 flex items-center justify-center text-sm">
            ⚡
          </div>
          <span className="font-bold text-lg">AffiliateOS</span>
          <button className="ml-auto lg:hidden text-white/50" onClick={() => setSidebarOpen(false)}>✕</button>
        </div>

        <nav className="flex-1 px-3 py-4 space-y-1">
          {NAV.map(({ href, icon, label }) => {
            const active = pathname === href || (href !== "/dashboard" && pathname.startsWith(href));
            return (
              <Link
                key={href}
                href={href}
                onClick={() => setSidebarOpen(false)}
                className={`
                  flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all
                  ${active ? "bg-violet-500/15 text-violet-400 border border-violet-500/20" : "text-white/50 hover:text-white hover:bg-white/5"}
                `}
              >
                <span>{icon}</span>
                {label}
              </Link>
            );
          })}
        </nav>

        <div className="px-3 py-4 border-t border-white/5">
          <div className="flex items-center gap-3 px-3 py-2 mb-1">
            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-violet-400 to-fuchsia-400 flex items-center justify-center text-xs font-bold">
              {user?.name?.charAt(0)?.toUpperCase()}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{user?.name}</p>
              <p className="text-xs text-white/40 truncate">{user?.email}</p>
            </div>
          </div>
          <button
            onClick={logout}
            className="flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-red-400/70 hover:text-red-400 hover:bg-red-500/10 w-full transition-colors"
          >
            🚪 Sair
          </button>
        </div>
      </aside>

      {sidebarOpen && (
        <div className="fixed inset-0 z-40 bg-black/60 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <header className="flex items-center gap-4 px-6 py-4 border-b border-white/5">
          <button className="lg:hidden text-white/50 hover:text-white" onClick={() => setSidebarOpen(true)}>
            ☰
          </button>
          <div className="flex-1" />
          <span className="text-white/30 text-sm">Bem-vindo, {user?.name}</span>
        </header>
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
'@

# ─── app/dashboard/page.tsx ───────────────────────────────
Set-Content -Path "apps/web/app/dashboard/page.tsx" -Value @'
"use client";

import { useEffect, useState } from "react";

const API = process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000/api/v1";

async function apiFetch(path: string) {
  const token = localStorage.getItem("accessToken");
  const res = await fetch(`${API}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const data = await res.json();
  return data.data;
}

export default function DashboardPage() {
  const [summary, setSummary] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiFetch("/analytics/summary")
      .then(setSummary)
      .finally(() => setLoading(false));
  }, []);

  const stats = summary ? [
    { label: "Produtos Prontos", value: summary.products.ready, sub: `de ${summary.products.total} total`, icon: "📦", color: "from-violet-500 to-fuchsia-500" },
    { label: "Posts Enviados", value: summary.posts.sent, sub: `${summary.posts.pending} pendentes`, icon: "📤", color: "from-blue-500 to-cyan-500" },
    { label: "Cliques Hoje", value: summary.clicks.today, sub: `${summary.clicks.week} esta semana`, icon: "👆", color: "from-emerald-500 to-teal-500" },
    { label: "Receita (7 dias)", value: `R$ ${Number(summary.revenue.week).toFixed(2).replace(".", ",")}`, sub: `Taxa: ${summary.conversions.rate}%`, icon: "💰", color: "from-amber-500 to-orange-500" },
  ] : [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <p className="text-white/40 text-sm mt-0.5">Visao geral da sua operacao</p>
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-40">
          <div className="text-white/40">Carregando...</div>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
          {stats.map(({ label, value, sub, icon, color }) => (
            <div key={label} className="bg-[#111118] border border-white/5 rounded-xl p-5 hover:border-white/10 transition-colors">
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-white/40 text-xs font-medium uppercase tracking-wider">{label}</p>
                  <p className="text-2xl font-bold mt-1">{value}</p>
                  <p className="text-white/30 text-xs mt-1">{sub}</p>
                </div>
                <div className={`w-10 h-10 rounded-lg bg-gradient-to-br ${color} flex items-center justify-center text-xl`}>
                  {icon}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <div className="bg-[#111118] border border-white/5 rounded-xl p-6">
        <h2 className="font-semibold mb-2">Proximos passos</h2>
        <div className="space-y-3 mt-4">
          {[
            { step: "1", text: "Adicione seu primeiro produto em Produtos", link: "/dashboard/products" },
            { step: "2", text: "Conecte seu WhatsApp em WhatsApp", link: "/dashboard/whatsapp" },
            { step: "3", text: "Agende sua primeira postagem em Agendamentos", link: "/dashboard/scheduler" },
          ].map(({ step, text, link }) => (
            <a key={step} href={link} className="flex items-center gap-3 p-3 rounded-lg hover:bg-white/5 transition-colors group">
              <div className="w-7 h-7 rounded-full bg-violet-500/20 text-violet-400 flex items-center justify-center text-sm font-bold flex-shrink-0">
                {step}
              </div>
              <span className="text-white/60 group-hover:text-white text-sm transition-colors">{text}</span>
              <span className="ml-auto text-white/20 group-hover:text-violet-400 transition-colors">→</span>
            </a>
          ))}
        </div>
      </div>
    </div>
  );
}
'@

# ─── app/dashboard/products/page.tsx ─────────────────────
New-Item -ItemType Directory -Force -Path "apps/web/app/dashboard/products" | Out-Null
Set-Content -Path "apps/web/app/dashboard/products/page.tsx" -Value @'
"use client";

import { useEffect, useState, useRef } from "react";
import toast from "react-hot-toast";

const API = process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000/api/v1";

async function apiFetch(path: string, options: any = {}) {
  const token = localStorage.getItem("accessToken");
  const res = await fetch(`${API}${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      ...(options.headers || {}),
    },
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || "Erro");
  return data.data;
}

const STATUS: Record<string, { label: string; color: string }> = {
  READY: { label: "Pronto", color: "text-emerald-400 bg-emerald-400/10" },
  PENDING: { label: "Aguardando", color: "text-amber-400 bg-amber-400/10" },
  SCRAPING: { label: "Processando", color: "text-blue-400 bg-blue-400/10" },
  ERROR: { label: "Erro", color: "text-red-400 bg-red-400/10" },
  ARCHIVED: { label: "Arquivado", color: "text-white/30 bg-white/5" },
};

const STORES: Record<string, string> = {
  SHOPEE: "Shopee", MERCADO_LIVRE: "Mercado Livre",
  AMAZON: "Amazon", SHEIN: "Shein", ALIEXPRESS: "AliExpress", OTHER: "Outro",
};

export default function ProductsPage() {
  const [products, setProducts] = useState<any[]>([]);
  const [pagination, setPagination] = useState({ page: 1, total: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [showAdd, setShowAdd] = useState(false);
  const [newUrl, setNewUrl] = useState("");
  const [adding, setAdding] = useState(false);
  const [bulkUrls, setBulkUrls] = useState("");
  const [showBulk, setShowBulk] = useState(false);

  useEffect(() => { loadProducts(1); }, [search]);

  async function loadProducts(page = 1) {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page: String(page), limit: "20", ...(search && { search }) });
      const result = await apiFetch(`/products?${params}`);
      setProducts(result.products);
      setPagination(result.pagination);
    } catch (e) {
      toast.error("Erro ao carregar produtos");
    } finally {
      setLoading(false);
    }
  }

  async function handleAdd() {
    if (!newUrl.trim()) return;
    setAdding(true);
    try {
      await apiFetch("/products", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ affiliateUrl: newUrl }),
      });
      toast.success("Produto adicionado! Processando...");
      setNewUrl(""); setShowAdd(false);
      loadProducts(1);
    } catch (e: any) {
      toast.error(e.message);
    } finally {
      setAdding(false);
    }
  }

  async function handleBulk() {
    const urls = bulkUrls.split("\n").map((u) => u.trim()).filter(Boolean);
    if (!urls.length) return;
    try {
      const result = await apiFetch("/products/bulk/urls", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ urls }),
      });
      toast.success(`${result.queued} produtos adicionados!`);
      setBulkUrls(""); setShowBulk(false);
      loadProducts(1);
    } catch (e: any) {
      toast.error(e.message);
    }
  }

  async function handleDelete(id: string) {
    if (!confirm("Deletar produto?")) return;
    try {
      await apiFetch(`/products/${id}`, { method: "DELETE" });
      toast.success("Produto deletado");
      loadProducts(pagination.page);
    } catch (e: any) { toast.error(e.message); }
  }

  async function handleGenerateCaptions(productId: string) {
    const t = toast.loading("Gerando legendas com IA...");
    try {
      await apiFetch("/captions/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ productId, styles: ["URGENCY", "DISCOUNT", "CASUAL", "VIRAL"], count: 2 }),
      });
      toast.success("Legendas geradas!", { id: t });
    } catch (e: any) { toast.error(e.message, { id: t }); }
  }

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Produtos</h1>
          <p className="text-white/40 text-sm">{pagination.total} produtos</p>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => setShowBulk(true)} className="flex items-center gap-2 px-3 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-sm text-white/70 border border-white/5 transition-all">
            📥 Importar em massa
          </button>
          <button onClick={() => setShowAdd(true)} className="flex items-center gap-2 px-4 py-2 rounded-lg bg-violet-500 hover:bg-violet-400 text-sm font-medium transition-colors">
            + Adicionar
          </button>
        </div>
      </div>

      <input
        type="text"
        placeholder="Buscar produtos..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        className="w-full max-w-sm bg-[#111118] border border-white/5 rounded-lg px-4 py-2 text-sm text-white placeholder-white/30 focus:outline-none focus:border-violet-500/50"
      />

      <div className="bg-[#111118] border border-white/5 rounded-xl overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-16 text-white/30">Carregando...</div>
        ) : products.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-white/30">
            <div className="text-4xl mb-3">📦</div>
            <p className="text-lg font-medium">Nenhum produto</p>
            <p className="text-sm mt-1">Adicione seu primeiro link de afiliado</p>
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-white/5">
                <th className="text-left px-4 py-3 text-white/30 font-medium">Produto</th>
                <th className="text-left px-4 py-3 text-white/30 font-medium hidden md:table-cell">Loja</th>
                <th className="text-left px-4 py-3 text-white/30 font-medium hidden lg:table-cell">Preco</th>
                <th className="text-left px-4 py-3 text-white/30 font-medium">Status</th>
                <th className="text-right px-4 py-3 text-white/30 font-medium">Acoes</th>
              </tr>
            </thead>
            <tbody>
              {products.map((p) => {
                const st = STATUS[p.status] || STATUS.PENDING;
                return (
                  <tr key={p.id} className="border-b border-white/5 hover:bg-white/[0.02] transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        {p.primaryImageUrl ? (
                          <img src={p.primaryImageUrl} alt="" className="w-10 h-10 rounded-lg object-cover bg-white/5 flex-shrink-0" />
                        ) : (
                          <div className="w-10 h-10 rounded-lg bg-white/5 flex items-center justify-center flex-shrink-0 text-lg">📦</div>
                        )}
                        <div className="min-w-0">
                          <p className="font-medium truncate max-w-[200px]">{p.title || "Processando..."}</p>
                          <a href={p.affiliateUrl} target="_blank" className="text-xs text-violet-400/60 hover:text-violet-400">
                            🔗 Link
                          </a>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell text-white/60">{STORES[p.store]}</td>
                    <td className="px-4 py-3 hidden lg:table-cell">
                      <div>
                        <span className="font-semibold">R$ {p.price ? Number(p.price).toFixed(2).replace(".", ",") : "—"}</span>
                        {p.discountPercent > 0 && <span className="ml-2 text-xs text-emerald-400">-{p.discountPercent}%</span>}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${st.color}`}>
                        {st.label}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center justify-end gap-1">
                        {p.status === "READY" && (
                          <button onClick={() => handleGenerateCaptions(p.id)} title="Gerar legendas" className="p-1.5 rounded-lg hover:bg-violet-500/20 text-violet-400/60 hover:text-violet-400 transition-colors">
                            ✨
                          </button>
                        )}
                        <button onClick={() => handleDelete(p.id)} className="p-1.5 rounded-lg hover:bg-red-500/20 text-red-400/60 hover:text-red-400 transition-colors">
                          🗑️
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}

        {pagination.totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-white/5">
            <p className="text-xs text-white/30">Pagina {pagination.page} de {pagination.totalPages}</p>
            <div className="flex gap-2">
              <button onClick={() => loadProducts(pagination.page - 1)} disabled={pagination.page <= 1} className="px-3 py-1 rounded bg-white/5 hover:bg-white/10 disabled:opacity-30 text-sm">←</button>
              <button onClick={() => loadProducts(pagination.page + 1)} disabled={pagination.page >= pagination.totalPages} className="px-3 py-1 rounded bg-white/5 hover:bg-white/10 disabled:opacity-30 text-sm">→</button>
            </div>
          </div>
        )}
      </div>

      {/* Modal adicionar */}
      {showAdd && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/70" onClick={() => setShowAdd(false)} />
          <div className="relative bg-[#111118] border border-white/10 rounded-xl p-6 w-full max-w-md">
            <h2 className="font-semibold text-lg mb-4">Adicionar Produto</h2>
            <label className="block text-sm text-white/60 mb-2">Link de Afiliado</label>
            <input
              type="url"
              value={newUrl}
              onChange={(e) => setNewUrl(e.target.value)}
              placeholder="https://shopee.com.br/..."
              className="w-full bg-[#0A0A0F] border border-white/10 rounded-lg px-4 py-3 text-sm text-white placeholder-white/20 focus:outline-none focus:border-violet-500/50 mb-4"
              autoFocus
            />
            <p className="text-xs text-white/30 mb-4">Suporte: Shopee, Mercado Livre, Amazon, Shein, AliExpress</p>
            <div className="flex gap-2 justify-end">
              <button onClick={() => setShowAdd(false)} className="px-4 py-2 rounded-lg text-sm text-white/50 hover:bg-white/5">Cancelar</button>
              <button onClick={handleAdd} disabled={adding || !newUrl} className="px-4 py-2 rounded-lg bg-violet-500 hover:bg-violet-400 text-sm font-medium disabled:opacity-50">
                {adding ? "Adicionando..." : "Adicionar"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal bulk */}
      {showBulk && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/70" onClick={() => setShowBulk(false)} />
          <div className="relative bg-[#111118] border border-white/10 rounded-xl p-6 w-full max-w-lg">
            <h2 className="font-semibold text-lg mb-4">Importar em Massa</h2>
            <label className="block text-sm text-white/60 mb-2">Cole os links (um por linha)</label>
            <textarea
              value={bulkUrls}
              onChange={(e) => setBulkUrls(e.target.value)}
              placeholder={"https://shopee.com.br/...\nhttps://mercadolivre.com.br/...\nhttps://amazon.com.br/..."}
              rows={8}
              className="w-full bg-[#0A0A0F] border border-white/10 rounded-lg px-4 py-3 text-sm text-white placeholder-white/20 focus:outline-none focus:border-violet-500/50 resize-none font-mono mb-4"
            />
            <div className="flex gap-2 justify-end">
              <button onClick={() => setShowBulk(false)} className="px-4 py-2 rounded-lg text-sm text-white/50 hover:bg-white/5">Cancelar</button>
              <button onClick={handleBulk} disabled={!bulkUrls.trim()} className="px-4 py-2 rounded-lg bg-violet-500 hover:bg-violet-400 text-sm font-medium disabled:opacity-50">
                Importar {bulkUrls.split("\n").filter(Boolean).length} links
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
'@

# ─── app/dashboard/settings/page.tsx ─────────────────────
New-Item -ItemType Directory -Force -Path "apps/web/app/dashboard/settings" | Out-Null
Set-Content -Path "apps/web/app/dashboard/settings/page.tsx" -Value @'
"use client";

export default function SettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Configuracoes</h1>
        <p className="text-white/40 text-sm">Gerencie sua conta e preferencias</p>
      </div>
      <div className="bg-[#111118] border border-white/5 rounded-xl p-6">
        <p className="text-white/40 text-sm">Em breve...</p>
      </div>
    </div>
  );
}
'@

# ─── app/dashboard/analytics/page.tsx ────────────────────
New-Item -ItemType Directory -Force -Path "apps/web/app/dashboard/analytics" | Out-Null
Set-Content -Path "apps/web/app/dashboard/analytics/page.tsx" -Value @'
"use client";

export default function AnalyticsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Analytics</h1>
        <p className="text-white/40 text-sm">Acompanhe seus resultados</p>
      </div>
      <div className="bg-[#111118] border border-white/5 rounded-xl p-6">
        <p className="text-white/40 text-sm">Adicione produtos e comece a postar para ver seus dados aqui.</p>
      </div>
    </div>
  );
}
'@

# ─── app/dashboard/whatsapp/page.tsx ─────────────────────
New-Item -ItemType Directory -Force -Path "apps/web/app/dashboard/whatsapp" | Out-Null
Set-Content -Path "apps/web/app/dashboard/whatsapp/page.tsx" -Value @'
"use client";

export default function WhatsAppPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">WhatsApp</h1>
        <p className="text-white/40 text-sm">Gerencie sua conexao e grupos</p>
      </div>
      <div className="bg-[#111118] border border-white/5 rounded-xl p-6">
        <p className="text-white/60 font-medium mb-2">Como conectar:</p>
        <ol className="list-decimal list-inside space-y-2 text-white/40 text-sm">
          <li>Configure o WHATSAPP_API_URL no arquivo .env da API</li>
          <li>Suba o Evolution API com o Docker</li>
          <li>Escaneie o QR Code com seu WhatsApp</li>
          <li>Clique em Sincronizar Grupos</li>
        </ol>
      </div>
    </div>
  );
}
'@

# ─── app/dashboard/scheduler/page.tsx ────────────────────
New-Item -ItemType Directory -Force -Path "apps/web/app/dashboard/scheduler" | Out-Null
Set-Content -Path "apps/web/app/dashboard/scheduler/page.tsx" -Value @'
"use client";

export default function SchedulerPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Agendamentos</h1>
        <p className="text-white/40 text-sm">Gerencie seus posts agendados</p>
      </div>
      <div className="bg-[#111118] border border-white/5 rounded-xl p-6">
        <p className="text-white/40 text-sm">Adicione produtos e conecte o WhatsApp para comecar a agendar posts.</p>
      </div>
    </div>
  );
}
'@

# ─── .env.local ───────────────────────────────────────────
Set-Content -Path "apps/web/.env.local" -Value @'
NEXT_PUBLIC_API_URL=http://localhost:4000/api/v1
NEXT_PUBLIC_WS_URL=http://localhost:4000
'@

Write-Host ""
Write-Host "Frontend criado com sucesso!" -ForegroundColor Green
Write-Host ""
