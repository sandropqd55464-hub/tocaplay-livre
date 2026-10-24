# TocaPlay VERSÃO 53 — Idiomas (PT, EN, ES, FR)
Arquivos para enviar à raiz do GitHub (9): index.html, admin.html, sw.js, LEIA-ME.md, i18n.js, i18n-en.js, i18n-es.js, i18n-fr.js, supabase_v53.sql
No Supabase (SQL Editor): rodar UMA vez o supabase_v53.sql (só cria a função dos países; não apaga nada).
- Botão de idioma (🌐 PT) no topo, com contorno dourado, ao lado de "Baixar app": Português, English, Español e Français.
- Quem abre com o navegador em outro idioma já vê o app nesse idioma; a escolha fica guardada.
- Link direto por idioma: tocaplaylivre.com.br/?lang=en (es, fr).
- Traduz menus, botões, avisos e descrições dos canais. Nomes de rádios, canais, vídeos e músicas não mudam.
- Mensagens de compartilhar no WhatsApp também saem no idioma escolhido.
- Barras de pesquisa (Buscar, Navegação, TV, Podcasts) com contorno dourado.
- Painel ADM: quadro "🌍 Fora do Brasil" com a bandeira de cada país e o número de pessoas dentro dela, e as cidades de fora.
- Painel ADM: "Federal District" agora aparece como Distrito Federal (somado ao DF).
- Contagem de acessos mais limpa: só conta depois de a pessoa tocar, clicar, rolar ou ficar 10 s na tela; e o functions/api/geo.js reconhece as redes das empresas de nuvem (Amazon, Google, Microsoft…).
- Correção (TV e celular): os vídeos do destaque da tela inicial não interrompem mais a rádio. Enquanto a pessoa ouve algo, o destaque mostra só a foto; na TV o destaque nunca roda vídeo.
- Para corrigir uma tradução: arquivos de texto t1/t2/t3 (linha: português || inglês || espanhol || francês).
(Inclui tudo das versões 50 a 52. config.js NÃO foi alterado.)
