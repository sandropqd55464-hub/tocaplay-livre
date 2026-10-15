/* =========================================================
   CONFIGURAÇÃO DO TOCAPLAY LIVRE
   Preencha com os dados do seu Supabase
   (Supabase → Project Settings → API).
   A chave "anon public" pode ficar aqui: a segurança vem
   das regras do banco. NUNCA cole a chave "service_role".
   ========================================================= */
const CONFIG = {
  SUPABASE_URL: 'https://odyrlnniwwefdwspzlch.supabase.co',
  SUPABASE_ANON_KEY: 'sb_publishable_vjFTbDiH7vbS047zvZsOCQ_gtbTIIcE',

  // Canais da aba "TV" (YouTube). Tocam os vídeos do canal dentro do app.
  // cat = categoria (vira um botão de filtro). live: true = mostra o botão "Ao vivo";
  // live: 'first' = já abre no ao vivo (canais de notícias 24h).
  // A foto do canal é buscada pelo endereço @ da url; se não carregar, aparecem as iniciais.
  // Para adicionar: no YouTube abra o canal → Mais informações → Compartilhar canal →
  // Copiar ID do canal (começa com UC) e copie um bloco abaixo.
  TV_CHANNELS: [
    { name: 'CazéTV', short: 'CZ', cat: 'Esportes', desc: 'Gols, resenha e ao vivo', url: 'https://www.youtube.com/@CazeTV', channelId: 'UCZiYbVptd3PVPf4f6eR6UaQ', live: true, color: 'linear-gradient(135deg,#ffd23f,#ff8a00)' },
    { name: 'Henrique e Juliano', short: 'HJ', cat: 'Sertanejo', desc: 'Clipes e ao vivo', url: 'https://www.youtube.com/@HenriqueeJuliano', channelId: 'UCfLTxnQboSLcoSakgONmukQ', color: 'linear-gradient(135deg,#c98b3a,#7a4a12)' },
    { name: 'Jorge & Mateus', short: 'JM', cat: 'Sertanejo', desc: 'Clipes oficiais', url: 'https://www.youtube.com/@jorgeemateus', channelId: 'UCL64gn1KZ1C-u87BGQv3b6w', color: 'linear-gradient(135deg,#c98b3a,#7a4a12)' },
    { name: 'Aline Barros', short: 'AB', cat: 'Gospel', desc: 'Louvor e adoração', url: 'https://www.youtube.com/@alinebarros', channelId: 'UCK_FvuzJN7rP4k2Ppwnvj5g', color: 'linear-gradient(135deg,#7c9cff,#5b3fd1)' },
    { name: 'Fernandinho', short: 'FE', cat: 'Gospel', desc: 'Louvor e adoração', url: 'https://www.youtube.com/@fernandinho', channelId: 'UCH1U29foC-5RyAa4ZgkuQYA', color: 'linear-gradient(135deg,#7c9cff,#5b3fd1)' },
    { name: 'Isadora Pompeo', short: 'IP', cat: 'Gospel', desc: 'Louvor e adoração', url: 'https://www.youtube.com/@isadorapompeo', channelId: 'UCAcbgThZJ4Iq-f1oPl4p8jw', color: 'linear-gradient(135deg,#7c9cff,#5b3fd1)' },
    { name: 'Pastor Antônio Júnior', short: 'AJ', cat: 'Pregações', desc: 'Pregações e mensagens', url: 'https://www.youtube.com/@prantoniojunior', channelId: 'UCKEM87jzVqdIfAdTr0xNBfA', live: true, color: 'linear-gradient(135deg,#b38bff,#3a1d8f)' },
    { name: 'Deive Leonardo', short: 'DL', cat: 'Pregações', desc: 'Pregações e mensagens', url: 'https://www.youtube.com/@deiveleonardoo', channelId: 'UCNMHZujkcJXErDXhLSGNVdA', live: true, color: 'linear-gradient(135deg,#b38bff,#3a1d8f)' },
    { name: 'Pr. Cláudio Duarte', short: 'CD', cat: 'Pregações', desc: 'Pregações e mensagens', url: 'https://www.youtube.com/channel/UCRXDOX4CbmrZsiom6e5Yj8g', channelId: 'UCRXDOX4CbmrZsiom6e5Yj8g', live: true, color: 'linear-gradient(135deg,#b38bff,#3a1d8f)' },
    { name: 'Pr. Josué Gonçalves', short: 'JG', cat: 'Pregações', desc: 'Família e casamento', url: 'https://www.youtube.com/@prjosuegoncalves', channelId: 'UCJp2_I4eXIrgP6mJabd1V0w', live: true, color: 'linear-gradient(135deg,#b38bff,#3a1d8f)' },
    { name: 'Rodrigo Silva', short: 'RS', cat: 'Pregações', desc: 'Evidências e arqueologia bíblica', url: 'https://www.youtube.com/@ntevidencias', channelId: 'UCDb1MVUkr_8kQ4mLfjBorGw', live: true, color: 'linear-gradient(135deg,#b38bff,#3a1d8f)' },
    { name: 'GR6 Explode', short: 'G6', cat: 'Funk e Urbana', desc: 'Funk e lançamentos', url: 'https://www.youtube.com/@GR6EXPLODE', channelId: 'UCNUQK9mQoqi4yNXw2_Rj6SA', color: 'linear-gradient(135deg,#ff4fa3,#9b1d64)' },
    { name: 'Anitta', short: 'AN', cat: 'Funk e Urbana', desc: 'Clipes oficiais', url: 'https://www.youtube.com/@anitta', channelId: 'UCqjjyPUghDSSKFBABM_CXMw', color: 'linear-gradient(135deg,#ff4fa3,#9b1d64)' },
    { name: 'Menos é Mais', short: 'ME', cat: 'Pagode', desc: 'Pagode ao vivo', url: 'https://www.youtube.com/@menosemais', channelId: 'UCY_FM2mQMfwbvNmvzXYVxOQ', color: 'linear-gradient(135deg,#ff7b54,#d72638)' },
    { name: 'Galinha Pintadinha', short: 'GP', cat: 'Infantil', desc: 'Músicas para crianças', url: 'https://www.youtube.com/@galinhapintadinha', channelId: 'UCBAb_DK4GYZqZR9MFA7y2Xg', color: 'linear-gradient(135deg,#9be15d,#00a86b)' },
    { name: 'Mundo Bita', short: 'MB', cat: 'Infantil', desc: 'Músicas para crianças', url: 'https://www.youtube.com/@MundoBita', channelId: 'UC0cGVh96osM7yqMu0ENSKKQ', color: 'linear-gradient(135deg,#9be15d,#00a86b)' },
    { name: 'Palavra Cantada', short: 'PC', cat: 'Infantil', desc: 'Músicas para crianças', url: 'https://www.youtube.com/@palavracantada', channelId: 'UCGs6qb1ohFhDzeHbYeJlsAA', color: 'linear-gradient(135deg,#9be15d,#00a86b)' },
    { name: 'Bob Zoom', short: 'BZ', cat: 'Infantil', desc: 'Músicas para crianças', url: 'https://www.youtube.com/@BobZoom', channelId: 'UCZcsG6kUpOLQZZpTMSAernw', color: 'linear-gradient(135deg,#9be15d,#00a86b)' },
    { name: 'Jovem Pan News', short: 'JP', cat: 'Notícias', desc: 'Jornalismo 24h', url: 'https://www.youtube.com/@jovempannews', channelId: 'UCP391YRAjSOdM_bwievgaZA', live: 'first', color: 'linear-gradient(135deg,#4aa3ff,#1f4e9c)' },
    { name: 'CNN Brasil', short: 'CN', cat: 'Notícias', desc: 'Jornalismo 24h', url: 'https://www.youtube.com/@CNNbrasil', channelId: 'UCvdwhh_fDyWccR42-rReZLw', live: 'first', color: 'linear-gradient(135deg,#4aa3ff,#1f4e9c)' },
    // ---- Aguardando confirmação do ID (a página do canal não abriu na consulta) ----
    // Para ativar: pegue o ID (UC...) do canal e tire as duas barras do começo da linha.
    // { name: 'Gusttavo Lima', short: 'GL', cat: 'Sertanejo', url: 'https://www.youtube.com/@gusttavolima', channelId: 'UC...' },
    // { name: 'Marília Mendonça', short: 'MM', cat: 'Sertanejo', url: 'https://www.youtube.com/@MariliaMendoncaOficial', channelId: 'UC...' },
    // { name: 'Gabriela Rocha', short: 'GR', cat: 'Gospel', url: 'https://www.youtube.com/@gabrielarocha', channelId: 'UC...' },
    // { name: 'KondZilla', short: 'KZ', cat: 'Funk e Urbana', url: 'https://www.youtube.com/@KondZilla', channelId: 'UC...' },
    // { name: 'Thiaguinho', short: 'TH', cat: 'Pagode', url: 'https://www.youtube.com/@Thiaguinho', channelId: 'UC...' },
    // { name: 'Ferrugem', short: 'FR', cat: 'Pagode', url: 'https://www.youtube.com/@ferrugem', channelId: 'UC...' },
    // { name: 'Tiago Brunet', short: 'TB', cat: 'Pregações', url: 'https://www.youtube.com/@tiagobrunetoficial', channelId: 'UC...' },
    // { name: 'Rev. Hernandes Dias Lopes', short: 'HL', cat: 'Pregações', channelId: 'UC...' },
    // { name: 'Pr. Lucinho Barreto', short: 'LB', cat: 'Pregações', channelId: 'UC...' },
    // Ana Castela: o link @anacastela leva a outro canal ("Ana Cordero") — confirmar o link oficial.
  ],

  // Google AdSense
  ADSENSE_CLIENT: 'ca-pub-9758861492456093',
  ADSENSE_SLOT: '',     // opcional: ID de um bloco fixo; os Anúncios automáticos funcionam sem isso

  // E-mail de contato mostrado nas páginas Sobre e Privacidade (deixe '' para não mostrar)
  CONTACT_EMAIL: 'sandropqd55464@gmail.com',
};
