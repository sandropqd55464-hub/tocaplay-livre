# TocaPlay VERSÃO 43 — Navegação na TV: tela inteira, margem de segurança e player maior; novas categorias, verificação de canais e TV com tudo de um lado

Arquivos da raiz do GitHub: index.html, admin.html, config.js, sw.js, LEIA-ME.md
Arquivo da pasta functions/api: yt.js (substitui o atual)

- Novas categorias na TV: Futebol (clubes oficiais e CBF TV), Gastronomia, Viagens e Lutas.
  Canais novos podem ser cadastrados só com o endereço do YouTube (@apelido ou /user/...): o app descobre o código sozinho.
  Endereço que não existir não aparece no app.
- Painel ADM: botão "🔎 Verificar canais" confere todos os canais (código certo, foto, nome) e gera a lista para corrigir.
- Smart TV: a faixa da direita foi para a coluna da esquerda (nada mais por cima do destaque nem dos vídeos).
- Inclui a versão 40 (barras fixas no topo, categorias da TV em dourado).

Pendente da versão 37: a pasta functions/api precisa ter _ads.js, ad-pay.js, mp-webhook.js e ad-refuse.js.
