# TocaPlay VERSÃO 47 — canais novos (times, viagens) não somem mais; Cinema livre (filmes que tocam dentro do app); serviços de filmes grátis também na tela "Todos" da TV; fotos dos artistas pelo nosso servidor; Navegação na TV: tela inteira, margem de segurança e player maior; novas categorias, verificação de canais e TV com tudo de um lado

Arquivos da raiz do GitHub: index.html, admin.html, config.js, sw.js, LEIA-ME.md
Arquivos da pasta functions/api: yt.js e cine.js (novo)

- Novas categorias na TV: Futebol (clubes oficiais e CBF TV), Gastronomia, Viagens e Lutas.
  Canais novos podem ser cadastrados só com o endereço do YouTube (@apelido ou /user/...): o app descobre o código sozinho.
  Endereço que não existir não aparece no app.
- Painel ADM: botão "🔎 Verificar canais" confere todos os canais (código certo, foto, nome) e gera a lista para corrigir.
- Smart TV: a faixa da direita foi para a coluna da esquerda (nada mais por cima do destaque nem dos vídeos).
- Inclui a versão 40 (barras fixas no topo, categorias da TV em dourado).

Novo na 44:
- Fotos dos canais/artistas vêm do nosso servidor (página do canal e, se falhar, o endereço @), não mais do unavatar.
- "Verificar canais": reconhece nomes escritos juntos no YouTube (ex.: DiantedoTronoOFICIAL) e confere a foto pelo @.
- "NCS Eletrônica" passa a se chamar "NCS (NoCopyrightSounds)".

Novo na 46:
- Categoria "🎬 Cinema livre" na aba TV: filmes em domínio público / licença livre do Internet Archive,
  tocando dentro do app (player grande, lista "Mais filmes" ao lado, Criar playlist e Anuncie aqui).
  Seções: Clássicos, Em português, Desenhos clássicos, Comédia, Faroeste e Terror. O servidor (cine.js) busca e guarda a lista por 24 h.

Pendente da versão 37: a pasta functions/api precisa ter _ads.js, ad-pay.js, mp-webhook.js e ad-refuse.js.
