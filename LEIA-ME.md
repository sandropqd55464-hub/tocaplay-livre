# TocaPlay Livre — passo a passo para colocar no ar

Mesmo esquema do PTTC: **código no GitHub → site no Netlify → login e favoritas no Supabase.**
Para corrigir ou mudar algo no futuro, edite os arquivos **no GitHub**; o Netlify publica sozinho em 1–2 minutos.

## O que tem na pasta

| Arquivo | Para que serve |
|---|---|
| `index.html` | O app inteiro (telas, player, busca, favoritas, cadastro, WhatsApp) |
| `config.js` | **Onde você cola as chaves do Supabase e do AdSense** |
| `admin.html` | Seu painel: cadastrados, acessos por dia, rádios mais ouvidas |
| `icon.svg`, `icon-192.png`, `icon-512.png` | Ícone do app (aparece ao instalar no celular) |
| `logo.png` | Logo completa para Instagram, WhatsApp, divulgação |
| `manifest.json`, `sw.js` | Permitem "Instalar app" na tela inicial do celular |
| `privacidade.html` | Política de privacidade (obrigatória para o AdSense) |
| `sobre.html`, `como-usar.html`, `radios-por-estado.html` | Páginas de conteúdo (ajudam na aprovação do AdSense e no Google) |
| `ads.txt` | Arquivo exigido pelo AdSense (autoriza a sua conta a exibir anúncios) |
| `netlify.toml` | Configuração do Netlify |
| `supabase.sql` | Cria as tabelas do banco no Supabase |

## 1. GitHub
1. Crie um repositório novo, por exemplo `tocaplay-livre`.
2. **Add file → Upload files** → arraste **todos os arquivos desta pasta** (não a pasta, os arquivos de dentro) → **Commit changes**.

## 2. Supabase (login e favoritas na nuvem)
1. Em supabase.com crie um projeto novo (ex.: `tocaplay`).
2. **SQL Editor → New query** → cole todo o conteúdo de `supabase.sql` → **Run**.
3. **Project Settings → API**: copie a **Project URL** e a chave **anon public**.
4. No GitHub, edite o `config.js` (lápis ✏️) e cole:
   ```js
   SUPABASE_URL: 'https://SEU-PROJETO.supabase.co',
   SUPABASE_ANON_KEY: 'sua-chave-anon',
   ```
   A chave **anon** pode ficar no arquivo, ela é pública. **Nunca** cole a `service_role`.
5. **Authentication → URL Configuration**: em **Site URL** coloque o endereço do Netlify (passo 3).

> Sem o Supabase o app já funciona: as favoritas ficam salvas só no aparelho.

## 3. Netlify
1. **Add new site → Import an existing project → GitHub** → escolha `tocaplay-livre`.
2. Não precisa mudar nada → **Deploy**.
3. Em **Domain management** dá para trocar o nome (ex.: `tocaplay.netlify.app`) ou ligar um domínio próprio.

## Painel do dono (cadastrados e acessos)
1. No app, aba **Conta**, crie sua conta com **sandropqd55464@gmail.com** e confirme pelo e-mail.
2. Acesse **seusite/admin.html** (ex.: `tocaplay-livre.netlify.app/admin.html`) e entre com esse e-mail e senha.
3. Só esse e-mail vê os números. Para trocar o dono, mude o e-mail dentro da função `admin_stats` no `supabase.sql` e rode de novo.

## 4. Instalar no celular
Abra o site no Chrome do Android → menu ⋮ → **Instalar app** (ou **Adicionar à tela inicial**). No iPhone: Safari → Compartilhar → **Adicionar à Tela de Início**. Fica com o ícone do TocaPlay e abre em tela cheia.

## 5. Google AdSense (renda)
1. Ter **domínio próprio** (ex.: `tocaplay-livre.com.br`) ligado no Netlify:
   - Registre em **registro.br** (pagamento anual, valor no próprio site).
   - Netlify → projeto **tocaplay-livre** → **Domain management** → **Add a domain** → digite o domínio.
   - O Netlify mostra os servidores DNS (ex.: `dns1.p01.nsone.net`). No registro.br, em **DNS → Alterar servidores DNS**, cole esses endereços. Em até 24h o site abre no domínio, já com cadeado (https).
   - Depois, no Supabase → **Authentication → URL Configuration**, troque a **Site URL** pelo domínio novo.
2. Em `privacidade.html`, troque o e-mail de contato pelo seu.
3. Cadastre o site em adsense.google.com e aguarde a aprovação (dias a semanas).
4. Aprovado: crie um bloco de anúncio "Display" e cole no `config.js`:
   ```js
   ADSENSE_CLIENT: 'ca-pub-XXXXXXXXXXXXXXXX',
   ADSENSE_SLOT: 'XXXXXXXXXX',
   ```
5. O AdSense também pede um arquivo `ads.txt`: crie no GitHub com a linha que eles mostrarem.

## AdSense (já configurado)
- Conta: `ca-pub-9758861492456093`. O código está no topo do `index.html` e das páginas, e o `ads.txt` está na pasta.
- Depois de aprovado, ative os **Anúncios automáticos** no painel do AdSense (Anúncios → Visão geral → editar o site). O Google escolhe sozinho os melhores lugares.
- Opcional: para um bloco fixo na tela inicial, crie um bloco "Display" e cole o ID em `ADSENSE_SLOT` no `config.js`.
- O e-mail de contato das páginas fica em `CONTACT_EMAIL` no `config.js`.

## Playlists
- **Criar sua playlist** fica na tela inicial (no computador, na coluna da esquerda).
- **Rádios:** toque no **+** de qualquer rádio.
- **Músicas:** dentro da playlist, toque em **🎵 Adicionar música**, procure no YouTube, copie o link do vídeo e cole. A música toca dentro do app pelo player oficial do YouTube e passa sozinha para a próxima.
- **Compartilhar:** o botão **Compartilhar** da playlist gera um link; quem abrir recebe a playlist pronta para salvar.
- As playlists ficam salvas no aparelho de cada pessoa.

## TV e vídeos
- Os canais ficam no `config.js` (lista `TV_CHANNELS`), separados por categoria: Esportes, Sertanejo, Gospel, Pregações, Funk e Urbana, Pagode, Infantil e Notícias.
- A **foto de cada canal** é buscada pelo endereço @ do canal (serviço gratuito unavatar.io). Se não carregar, aparecem as iniciais. Para fixar uma foto, coloque `avatar: 'link-da-imagem'` no canal.
- **Vídeos novos entram sozinhos:** o app sempre mostra os últimos vídeos publicados pelo canal.
- Ao tocar num canal, abrem os **últimos vídeos do canal dentro do app**. Canais com o botão **🔴 Ao vivo** também mostram a transmissão quando estão ao vivo; os de notícias já abrem no ao vivo.
- Se um vídeo aparecer como indisponível, o dono do canal bloqueou a exibição em outros sites; é só pular para o próximo no próprio player.
- Canais aguardando ID estão no `config.js` como linhas comentadas (`//`).

## No carro
- Conecte o celular ao carro por **Bluetooth** ou cabo e toque a rádio pelo TocaPlay.
- O nome da rádio aparece na tela do carro, e os botões **⏮ ⏭ do volante** trocam de rádio (na lista ou na playlist que estiver tocando).
- O TocaPlay ainda **não aparece dentro do Android Auto / Apple CarPlay**: esses sistemas só aceitam aplicativos de loja (Play Store / App Store).
- Músicas do YouTube precisam da tela ligada; rádios tocam com a tela desligada.

## Bom saber
- **De onde vêm as rádios:** diretório público e gratuito radio-browser.info (milhares de rádios do Brasil). Só entram rádios com transmissão segura (https), que são as que tocam em site publicado.
- **Rádio fora do ar:** algumas emissoras mudam o link; o app avisa e é só escolher outra.
- **Tela bloqueada:** no Android a rádio continua tocando com controles na notificação. No iPhone, ela também toca com a tela bloqueada se o app foi aberto pela tela inicial.
- **Mais tocadas no seu app:** rode no SQL Editor a consulta comentada no final do `supabase.sql`.
- **Atualizou o `index.html` e o celular mostra a versão velha?** No `sw.js`, aumente o número em `tocaplay-v11` (ex.: `tocaplay-v12`).

## Versão 11 (17/10/2026)
- **Inscrever-se com 1 toque:** botão vermelho na página inicial e na aba Conta. Cria uma inscrição sem digitar nada.
  - Precisa estar ligado no Supabase: **Authentication → Sign In / Providers → Allow anonymous sign-ins**.
- **Convite para baixar o app** logo depois de inscrever (Android e computador instalam com 1 toque; no iPhone mostra os passos).
- **Acesso ADM:** link discreto no rodapé da página inicial (leva ao `admin.html`).
- **Painel:** mostra inscritos (1 toque × e-mail) e instalações por aparelho. Rode o `supabase.sql` de novo para criar a tabela `installs`.
- **Aba TV:** categorias com subcategorias (Cristão, TV Ao Vivo, Internacionais, Músicas para Dormir, Infantil, Esportes, Filmes…) e busca de canal.
  Os canais ficam em `config.js` → `TV_CHANNELS`. Use `sub` para a subcategoria.

## Versão 12 (17/10/2026)
- **Página inicial nova:** destaque grande que troca sozinho. No computador e no Wi‑Fi roda o vídeo do canal sem som; no 4G mostra a imagem com movimento lento (economiza internet).
  - Para trocar os destaques: `config.js` → `HOME_FEATURED: ['Nome do canal', ...]` (nomes iguais aos da lista de canais).
  - Para desligar o vídeo: `HOME_VIDEO: false`.
- **TV:** se um vídeo do canal estiver bloqueado, o player pula sozinho para o próximo; se o canal não liberar nenhum, aparece o botão "Abrir no YouTube".
- **Aba Perfil:** antes de inscrever aparece como "Inscrever"; para o dono, mostra o botão "Abrir meu painel" (e-mail em `OWNER_EMAIL` no config.js).
- **Fileiras** "Ao vivo agora" e "Pregadores" com foto, que abrem direto na aba TV.

## Versão 13 (17/10/2026)
- **Destaque com som:** o vídeo do topo roda também no celular. Os navegadores só liberam som depois do primeiro toque na tela; no primeiro toque o som liga sozinho. Botão "🔇 Ouvir / 🔊" no canto do destaque.
  - Quando a pessoa toca uma rádio, uma música ou abre um vídeo, o destaque fica mudo e segue só o que ela escolheu.
- **Baixar app em destaque:** botão amarelo pulsando no topo e faixa grande "Baixe o app TocaPlay" na página inicial.
- **Inscrever-se** sempre visível na página inicial (para quem já é inscrito aparece "✓ Inscrito").
- **Canais novos:** Pra. Talitha Pereira, Pr. Arthur Pereira, Semeadores Kids, Bíblia Kids. Foto do Pr. Cláudio Duarte corrigida.
- Aba TV: no "Tudo" de uma categoria, cada canal aparece uma vez só.

## Versão 14 (17/10/2026)
- **Destaque vira apresentação do app:** puxa sozinho 2 canais de cada categoria (sorteados a cada visita) e mostra cada um por 10 segundos, com barra de progresso e contador (ex.: 3 / 19) com setas ‹ ›.
  - Ajuste em `config.js`: `HOME_PER_CATEGORY` (canais por categoria) e `HOME_SECONDS` (segundos de cada um).
  - Os vídeos começam a partir dos 25 segundos, para pular aberturas.

## Versão 15 (17/10/2026)
- Setas ‹ › nas fileiras "Ao vivo agora" e "Pregadores" (aparecem só quando há mais canais daquele lado).

## Versão 16 (17/10/2026)
- **Podcasts de vários assuntos, com preferência por vídeo.**
  - **Em vídeo (YouTube):** Flow, Podpah, Inteligência Ltda, Ticaracaticast, Charla (esportes), Ciência Sem Fim, Jovem Nerd, Os Sócios, PrimoCast, Me Poupe!, Drauzio Varella (saúde), Modus Operandi (crimes reais), JesusCopy e Dois Dedos de Teologia. Ficam no topo da aba Podcasts, na fileira "Podcasts em vídeo" da página inicial e na categoria "Podcasts" da TV.
  - **Só áudio:** 32 assuntos (Notícias, Humor, Esportes, Futebol, Entrevistas, Música, Educação, Ciência, História, Tecnologia, Games, Cinema e séries, Crimes reais, Saúde, Carreira, Dinheiro, Empreendedorismo, Idiomas, Concursos, Culinária, Viagem, Agro, Política, Livros, Infantil, Cristão, Católico e outros). A aba abre em "Destaques", com um pouco de cada.
  - Ao escolher um assunto, a fileira de vídeo mostra os podcasts em vídeo daquele assunto.
  - Episódios de áudio: "Seguir", "Continuar de onde parou", voltar 15s, avançar 30s e velocidade até 2x.
  - Podcasts em vídeo ficam em `config.js` (categoria `'Podcasts'`); assuntos de áudio em `index.html` → `POD_CATS`.
- Setas ‹ › também nas categorias da TV e dos Podcasts.

## Versão 17 (17/10/2026)
- **Aba Podcasts abre com todos os podcasts em vídeo (32), separados por assunto:**
  - Entrevistas: Flow, Podpah, Inteligência Ltda, Vênus, PodDelas, À Deriva
  - Humor: Ticaracaticast, Achismos, Papagaio Falante, Desce a Letra
  - Esportes: Charla, Benja Me Mucho, Denílson Show
  - Cristão: Café com Deus Pai, Karina Bacchi, Forte Podcast (Tassos Lycurgo), JesusCopy, Dois Dedos de Teologia
  - Dinheiro e negócios: Os Sócios, PrimoCast, Me Poupe!, Joel Jota, Irmãos Dias
  - Saúde: Drauzio Varella, Paulo Muzy, Psicologia na Prática
  - Crimes e mistério: Beto Ribeiro, Modus Operandi, LendaCast
  - Ciência e educação: Ciência Sem Fim, Jovem Nerd
  - Católico: Padre Alex Nogueira
- Embaixo continuam os podcasts só de áudio (32 assuntos).

## Versão 18 (17/10/2026)
- **Painel na lateral direita (computador):** "Rádio boa, de graça, do Oiapoque ao Chuí." com selo "100% grátis", números do app e botões "Baixar o app" e "Indicar no WhatsApp". Aparece em telas a partir de 1340px de largura.

## Versão 19 (17/10/2026)
- Nomes dos assuntos (Entrevistas, Humor, Saúde…) em branco forte, maiores e com marca amarela; botões de categoria mais claros. Vale para Podcasts e TV.
- Capas dos podcasts em vídeo com a imagem oficial do canal em destaque e fundo desfocado nas cores dele.

## Versão 20 (18/10/2026)
- **💪 Malhação:** nova categoria na TV e fileira na página inicial.
  - Música: Power Music Workout, Workout Music Source, NCS Eletrônica, FitDance.
  - Aulas: Carol Borba, Chloe Ting, Pamela Reif, Fitness Blender, Yoga With Adriene, Pri Leite Yoga, Leandro Twin.
  - Subcategorias: Aquecimento, Treino Pesado, Cardio/HIIT, Funcional, Aulas em casa, Alongamento e Yoga, Dicas de treino.
- **🏋️ Modo Academia:** tela cheia, relógio grande, toca sem parar (repete a lista do canal), tela não apaga, botões "Próxima música", "Trocar de canal" e "Sair". Aviso do ECAD no rodapé.

## Versão 21 (18/10/2026)
- **Painel do dono:**
  - **Visitantes reais** (30 dias, 7 dias e desde o início), sem contar robôs e buscadores.
  - **Acesso por área:** Início, Rádios, TV, cada categoria da TV, Pregações, Podcasts, Malhação, Modo Academia… e gráfico por dia de cada área.
  - **De onde são:** mapa do Brasil por estado, ranking de estados e cidades (aproximado; só cidade e estado são guardados, por causa da LGPD).
  - **Mais vistos:** TV mais assistida e podcasts mais ouvidos, além das rádios.
- Arquivo novo: `netlify/edge-functions/geo.js` (informa cidade e estado ao app; grátis no Netlify).
- **Rode o `supabase.sql` de novo** no SQL Editor (cria a tabela de áreas e as colunas de cidade e estado).

## Versão 22 (18/10/2026)
- **🚗 Carro e fone Bluetooth:** o visor mostra o nome da rádio com "TocaPlay"; os botões ⏭ ⏮ do volante trocam de rádio sempre (usa as favoritas ou a lista de onde a rádio veio). Nos podcasts, ⏭ avança 30s e ⏮ volta 15s.
- **📺 Modo TV automático** (LG webOS, Samsung Tizen, Android TV e outras):
  - Corrige a altura do vídeo em navegadores antigos de TV (o vídeo da TV e o destaque da página inicial voltam a aparecer).
  - Navegação pelas setas do controle remoto, com o item selecionado em amarelo; botão Voltar do controle LG funciona.
  - Rádio tenta reconectar sozinha se travar; "Abrir no YouTube" escondido; letras um pouco maiores.

## Versão 23 (18/10/2026)
- **⛪ Novos pregadores:** Pr. André Valadão, Pr. André Fernandes, Pr. Teo Hayashi e Pra. Júnia Hayashi.
- **Cultos e Missas ao vivo** (nova categoria na TV):
  - Evangélicas: Lagoinha Global, Bola de Neve, Videira, Dunamis.
  - Católicas: Canção Nova, Santuário de Aparecida, TV Pai Eterno, Rede Século 21.
  - Abre direto na transmissão ao vivo; se a igreja não estiver transmitindo, toca sozinho o último culto/missa gravado. Vale também para a TV Ao Vivo.
- **🎬 Filmes grátis:** além de NetMovies e Graça Filmes (tocam no app), botões para Pluto TV, Libreflix, Plex, Tela Brasil, Spcine Play e Mercado Play (abrem fora do app).

## Versão 24 (18/10/2026)
- **🎤 Galeria Gospel:** subcategorias "Gospel Nacional" (49 artistas) e "Gospel Internacional" na aba Cristão, com foto redonda grande de cada artista; fileira "Galeria Gospel" na página inicial.
- **🔎 Busca:** a lupa agora acha artistas, pregadores e canais pelo nome (ex.: "Anderson Freire"), além das rádios.
- **📻 Rádios Gospel:** fileira na página inicial; continuam tocando com a tela desligada ou em outro app, com controles na tela de bloqueio.
- **💡 Dica no player de vídeo:** avisa que vídeos do YouTube param fora do app e oferece "Ouvir rádio gospel".

## Versão 25 (19/10/2026)
- Hospedagem agora na Cloudflare Pages (grátis, sem limite de visitas). O GitHub publica sozinho a cada envio.
- Propaganda organizada: espaços reservados (abaixo do destaque, no meio da página inicial, antes da lista de rádios, no fim, em Podcasts e em TV), com o rótulo "Publicidade". Só são preenchidos quando ADSENSE_SLOT estiver no config.js; até lá, valem os Anúncios automáticos do Google.
- A faixa fixa do Google no rodapé não cobre mais o player nem a barra de baixo: os dois sobem sozinhos.
- Banners do próprio TocaPlay girando no destaque, junto com os vídeos (app, Modo Academia, Galeria Gospel, Rádios Românticas, rádio gospel fora do app, Cultos e Missas, convite no WhatsApp).
- Nova fileira "💕 Rádios Românticas" na página inicial.
- Páginas de conteúdo novas: radios-gospel.html, artistas-gospel.html e radios-romanticas.html (ajudam no AdSense e no Google).
- Painel: acessos de servidores de nuvem (robôs) não contam mais; o "Não identificado" saiu do ranking de estados e virou uma linha "sem localização".
- Para fazer no AdSense: em Anúncios automáticos, marque como "área excluída" o destaque animado do topo e o player.

## Versão 26 (19/10/2026) — Navegação, Etapa 1
- Botão "🧭 NAVEGAÇÃO" no destaque da página inicial (e um banner próprio no carrossel).
- Tela de Navegação: vídeo grande, curtir, comentar, compartilhar, denunciar e "Próximo"; lista "A seguir" à direita (no celular, embaixo), com espaço de propaganda a cada 6 vídeos.
- Abas "Para você" (algoritmo que aprende com o que a pessoa assiste, curte, compartilha e pula; 1 em cada 5 é novidade) e "Geral" (em alta no TocaPlay + mistura).
- Curtidas, comentários, visualizações e compartilhamentos contados pelo TocaPlay, do zero.
- Moderação automática: palavrão e link vão para a fila; 3 denúncias tiram o vídeo ou comentário do ar; limite de 5 comentários a cada 10 minutos.
- Painel ADM: números da Navegação e fila de revisão com Aprovar/Remover.
- Rodapé da página inicial corrigido (os links ficavam escondidos atrás da barra de baixo).
- SQL novo: parte "Navegação TocaPlay" no fim do supabase.sql (rodar uma vez).

## Versão 27/28 (19/10/2026)
- Navegação em tela inteira no computador (vídeo grande + corredor de vídeos à direita), botão NAVEGAÇÃO vermelho, clicar no vídeo do destaque abre a Navegação.
- Comentários fechados atrás do ícone 💬; quem tem conta comenta com o nome da conta, sem aviso.
- Filtro forte: palavrão, ofensa, sexual/obsceno, pornografia, ameaça e ódio são bloqueados na hora (também com truques como p0rr4 ou porrraaa). Link vai para a revisão. SQL: parte "filtro forte (versão 28)" no fim do supabase.sql.

## Versão 29 (19/10/2026) — Navegação, Etapa 2: Criadores
- Entrar com o Google (Inscrever-se, Perfil, + Criar e Meu canal).
- "+ Criar" e foto da conta no topo da Navegação. Postar por link: YouTube (e Shorts), TikTok e Instagram Reels, com título, categoria e aceite dos Termos.
- Aprovação automática com filtro forte no título; quem já teve post removido passa pela revisão; limite de 10 posts por dia.
- Vídeos de criadores entram na Navegação (1 a cada 4 no "Para você" e primeiro no "Geral"), com curtir, comentar e compartilhar.
- "Meu canal": desempenho (visualizações, curtidas, comentários, compartilhamentos), compartilhar e apagar.
- Página termos.html. Painel ADM: criadores, posts e posts na fila de revisão.
- SQL: parte "Etapa 2: Criadores (versão 29)" no fim do supabase.sql.

## Versão 30/31 (19/10/2026) — Etapa 3: enviar do aparelho
- Perfil: quadro "Meu canal de criador" com "+ Criar conteúdo" e "Ver meu canal".
- + Criar conteúdo com duas abas: "📁 Enviar do aparelho" (vídeo até 60 s ou foto) e "🔗 Colar link". Emojis rápidos no título.
- O vídeo é comprimido no próprio aparelho e ganha a marca d'água "TocaPlay Livre"; a foto também. Envio com barra de progresso.
- Guardado no Supabase Storage (pasta "posts", 1 GB grátis). Limite: 5 envios por dia por pessoa, 20 MB por arquivo; acima de 950 MB no total, novos envios param.
- Botão "⬇ Baixar" na Navegação e no Meu canal para vídeos e fotos enviados.
- Painel ADM: espaço usado. SQL: parte "Etapa 3 (versão 31)" no fim do supabase.sql.

## Versão 32 (19/10/2026)
- Navegação abre como a página inicial do YouTube: grade de vídeos grandes, 3 por linha no computador (2 no tablet, 1 no celular), com capa, título, canal e categoria; carrega mais sozinho ao rolar; propaganda a cada 2 linhas.
- Tocou num vídeo: abre a tela de assistir (vídeo grande + "A seguir" ao lado). Botão "‹ Todos os vídeos" (e o voltar do celular) retorna à grade.
- Títulos reais dos vídeos (oEmbed do YouTube, guardados no aparelho).

## Versão 33 (19/10/2026)
- Títulos das seções (Ao vivo agora, Pregadores, Galeria Gospel, Rádios Românticas, Podcasts, Malhação etc.) em dourado com brilho passando, igual à barra de baixo.

## Versão 34 (19/10/2026) — impulso para criadores
- Post novo (até 72 h) aparece primeiro; entre os novos, os menos vistos vão na frente (todo post chega a bastante gente).
- Na Navegação: um vídeo de criador logo no começo do "Para você" e 1 a cada 3 vídeos.
- Página inicial: fileira "🎬 Novos no TocaPlay" com os vídeos do público.
- Política de privacidade atualizada (login Google, envios, comentários, LGPD).
