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
