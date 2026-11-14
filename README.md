# 🧀 Entregas de Queijo

App simples (funciona no navegador do celular) para organizar pedidos agendados pelo WhatsApp e fazer a rota de entrega.

## Como funciona
1. **⚙︎ Configurações** – coloque seu WhatsApp. O app gera um **link para o anúncio**: o cliente clica e o WhatsApp abre com uma mensagem modelo (Nome, Endereço, Pedido, Dia...).
2. **Pedidos** – quando a mensagem chegar, copie e cole em “Novo pedido” → “Preencher com a mensagem”. Toque em “Buscar endereço no mapa” (ou marque o local no mapa) e salve.
3. **Rota** – escolha o dia e toque em **Iniciar rota**. O app usa o GPS, mostra todos os clientes no mapa e indica a **entrega mais perto**. Botões para abrir no Google Maps / Waze, avisar o cliente no WhatsApp e ligar. Toque em **“Entreguei — próximo”** e ele recalcula o próximo mais perto de onde você está.

Os dados ficam salvos no próprio celular (use Exportar/Importar para backup).

## Como colocar no ar
É só um site estático (`index.html`). Pode publicar grátis no GitHub Pages, Vercel ou Netlify. Precisa ser **https** para o GPS funcionar. No celular, use “Adicionar à tela inicial” para virar um ícone de app.
