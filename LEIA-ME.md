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

## Bom saber
- **De onde vêm as rádios:** diretório público e gratuito radio-browser.info (milhares de rádios do Brasil). Só entram rádios com transmissão segura (https), que são as que tocam em site publicado.
- **Rádio fora do ar:** algumas emissoras mudam o link; o app avisa e é só escolher outra.
- **Tela bloqueada:** no Android a rádio continua tocando com controles na notificação. No iPhone, ela também toca com a tela bloqueada se o app foi aberto pela tela inicial.
- **Mais tocadas no seu app:** rode no SQL Editor a consulta comentada no final do `supabase.sql`.
- **Atualizou o `index.html` e o celular mostra a versão velha?** No `sw.js`, aumente o número em `tocaplay-v2` (ex.: `tocaplay-v3`).
