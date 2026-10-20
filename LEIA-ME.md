# TocaPlay VERSÃO 40 — barras fixas no topo e títulos da TV em dourado

Arquivos da raiz do GitHub: index.html, admin.html, sw.js, LEIA-ME.md
SQL (Supabase, projeto tocaplay): SQL_VERSAO_39_estado_inscritos.sql

Inclui a versão 38:
- Vídeo em tela larga / Smart TV: player à esquerda e uma coluna só à direita (nada por cima do vídeo); botão "Tela cheia".
- Card roxo "Anuncie aqui" ao lado de "Criar sua playlist" (pulsa 3 vezes ao aparecer).

Novo na 39:
- Acesso por área: cliques (banner, sub-abas da Navegação, envio de vídeo) não contam mais como acesso;
  "Busca de rádios" entra em Rádios e "Podcasts (áudio)" / "TV · Podcasts" em Podcasts. O painel limpa também os registros antigos.
- Inscritos sem estado (Google / 1 toque): o app pede o estado uma vez, já sugerindo o da internet.

Novo na 40:
- Barras fixas no topo ao rolar: Navegação (Para você / Geral / + Criar / pesquisa), TV (pesquisa e categorias), Podcasts e Buscar.
- Aba TV: nomes das categorias em dourado (como na tela inicial) e cartões um pouco maiores no computador.

Pendente da versão 37: a pasta functions/api precisa ter _ads.js, ad-pay.js, mp-webhook.js e ad-refuse.js.
