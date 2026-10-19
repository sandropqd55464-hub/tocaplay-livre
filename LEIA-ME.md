# TocaPlay VERSÃO 37 — Anúncios pagos (Pix ou cartão)

Arquivos da raiz do GitHub: index.html, admin.html, anunciar.html, sw.js, sitemap.xml
Arquivos da pasta functions/api: _ads.js, ad-pay.js, mp-webhook.js, ad-refuse.js
SQL (Supabase, projeto tocaplay): SQL_VERSAO_37_anuncios.sql

Variáveis no Cloudflare (Settings → Variables and Secrets, tipo Secret):
- MP_ACCESS_TOKEN = Access Token de produção do Mercado Pago (APP_USR-...)
- SUPABASE_SECRET_KEY = chave secreta do Supabase (Settings → API Keys → Secret keys)
Nunca envie essas chaves por mensagem ou print.
