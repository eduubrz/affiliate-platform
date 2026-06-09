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
