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
