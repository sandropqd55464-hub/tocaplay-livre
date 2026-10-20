// Cloudflare Pages: lista os últimos vídeos de um canal do YouTube que PODEM tocar fora do YouTube,
// com título, e a foto (avatar) do canal. Grátis: usa o RSS público e o oEmbed do próprio YouTube.
// GET /api/yt?c=UCxxxx          -> {videos:[{id,title}], avatar}
// GET /api/yt?c=UCxxxx&av=1     -> redireciona para a foto do canal (para usar direto em <img>)
// GET /api/yt?h=@apelido         -> {id, name, avatar}: descobre o código (UC...) do canal pelo endereço @
const CACHE_SEC = 6 * 3600;

async function getAvatar(c) {
  try {
    const r = await fetch(`https://www.youtube.com/channel/${c}`, { headers: { 'accept-language': 'pt-BR,pt;q=0.9', 'user-agent': 'Mozilla/5.0' } });
    const html = await r.text();
    const m = html.match(/<meta property="og:image" content="([^"]+)"/) || html.match(/"avatar":\{"thumbnails":\[\{"url":"(https:[^"]+)"/);
    return m ? m[1].replace(/\\u0026/g, '&').replace(/=s\d+-/, '=s240-') : null;
  } catch { return null; }
}

async function embeddable(id) {
  try {
    const r = await fetch(`https://www.youtube.com/oembed?format=json&url=${encodeURIComponent('https://www.youtube.com/watch?v=' + id)}`);
    return r.ok;   // 401/403 = o dono não libera tocar fora do YouTube
  } catch { return true; }
}

async function build(c) {
  let videos = [], name = '';
  try {
    const r = await fetch(`https://www.youtube.com/feeds/videos.xml?channel_id=${c}`);
    const xml = await r.text();
    const entries = xml.split('<entry>').slice(1);
    videos = entries.map(e => ({
      id: (e.match(/<yt:videoId>([\w-]{11})<\/yt:videoId>/) || [])[1],
      title: ((e.match(/<title>([\s\S]*?)<\/title>/) || [])[1] || '').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>'),
      shorts: /\/shorts\//.test(e)
    })).filter(v => v.id);
    name = ((xml.match(/<author>\s*<name>([^<]+)<\/name>/) || xml.match(/<title>([^<]+)<\/title>/) || [])[1] || '').replace(/&amp;/g, '&').trim();
  } catch {}
  const checks = await Promise.all(videos.slice(0, 15).map(v => embeddable(v.id)));
  const ok = videos.slice(0, 15).filter((v, i) => checks[i]).map(({ id, title, shorts }) => ({ id, title, shorts }));
  const avatar = await getAvatar(c);
  return { videos: ok, total: videos.length, avatar, name };
}

async function byHandle(h) {
  try {
    const r = await fetch(/^(user|c)\//.test(h) ? `https://www.youtube.com/${h}` : `https://www.youtube.com/@${encodeURIComponent(h)}`, { headers: { 'accept-language': 'pt-BR,pt;q=0.9', 'user-agent': 'Mozilla/5.0' } });
    if (!r.ok) return { id: null };
    const html = await r.text();
    const id = (html.match(/<link rel="canonical" href="https:\/\/www\.youtube\.com\/channel\/(UC[\w-]{22})"/) || html.match(/"externalId":"(UC[\w-]{22})"/) || html.match(/"channelId":"(UC[\w-]{22})"/) || [])[1] || null;
    const name = ((html.match(/<meta property="og:title" content="([^"]+)"/) || [])[1] || '').replace(/&amp;/g, '&');
    const av = (html.match(/<meta property="og:image" content="([^"]+)"/) || [])[1] || null;
    return { id, name, avatar: av };
  } catch { return { id: null }; }
}

export async function onRequest(context) {
  const url = new URL(context.request.url);
  const h = (url.searchParams.get('h') || '').replace(/^@/, '');   // aceita @apelido, user/nome ou c/nome
  if (h) {
    if (!/^((user|c)\/)?[\w.\-]{2,60}$/.test(h)) return new Response('{"error":"apelido"}', { status: 400, headers: { 'content-type': 'application/json' } });
    const cache = caches.default, key = new Request(`https://tocaplay-cache/yth/${h.toLowerCase()}`);
    let hit = await cache.match(key), data;
    if (hit) data = await hit.json();
    else { data = await byHandle(h); if (data.id) context.waitUntil(cache.put(key, new Response(JSON.stringify(data), { headers: { 'content-type': 'application/json', 'cache-control': `public, max-age=${CACHE_SEC * 4}` } }))); }
    return new Response(JSON.stringify(data), { headers: { 'content-type': 'application/json; charset=utf-8' } });
  }
  const c = url.searchParams.get('c') || '';
  if (!/^UC[\w-]{22}$/.test(c)) return new Response('{"error":"canal"}', { status: 400, headers: { 'content-type': 'application/json' } });
  const cache = caches.default;
  const key = new Request(`https://tocaplay-cache/yt2/${c}`);
  let data;
  const hit = await cache.match(key);
  if (hit) data = await hit.json();
  else {
    data = await build(c);
    const resp = new Response(JSON.stringify(data), { headers: { 'content-type': 'application/json', 'cache-control': `public, max-age=${CACHE_SEC}` } });
    context.waitUntil(cache.put(key, resp.clone()));
  }
  if (url.searchParams.get('av')) {
    if (data.avatar) return Response.redirect(data.avatar, 302);
    return new Response('', { status: 404 });
  }
  return new Response(JSON.stringify(data), { headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'public, max-age=1800' } });
}
