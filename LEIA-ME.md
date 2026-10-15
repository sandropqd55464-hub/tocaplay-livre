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
