/* =========================================================
   CONFIGURAÇÃO DO TOCAPLAY LIVRE
   Preencha com os dados do seu Supabase
   (Supabase → Project Settings → API).
   A chave "anon public" pode ficar aqui: a segurança vem
   das regras do banco. NUNCA cole a chave "service_role".
   ========================================================= */
const CONFIG = {
  SUPABASE_URL: 'COLE_AQUI_A_URL_DO_SUPABASE',   // ex: https://xxxx.supabase.co
  SUPABASE_ANON_KEY: 'COLE_AQUI_A_ANON_KEY',

  // Canais da aba "TV ao vivo" (YouTube).
  // Para adicionar um canal: abra o canal no YouTube → Mais informações →
  // Compartilhar canal → Copiar ID do canal (começa com UC) e copie um bloco abaixo.
  TV_CHANNELS: [
    {
      name: 'CazéTV',
      short: 'CZ',
      desc: 'Esportes ao vivo, jogos e resenha',
      channelId: 'UCZiYbVptd3PVPf4f6eR6UaQ',
      url: 'https://www.youtube.com/@CazeTV/live',
      color: 'linear-gradient(135deg,#ffd23f,#ff8a00)',
    },
    // { name: 'Outro canal', short: 'OC', desc: 'Descrição', channelId: 'UC...', url: 'https://www.youtube.com/@canal/live' },
  ],

  // Google AdSense — deixe vazio até a conta ser aprovada
  ADSENSE_CLIENT: '',   // ex: 'ca-pub-1234567890123456'
  ADSENSE_SLOT: '',     // ID do bloco de anúncio
};
