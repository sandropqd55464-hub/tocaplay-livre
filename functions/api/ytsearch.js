// Cloudflare Pages: busca completa no YouTube (API oficial YouTube Data v3, cota grátis do Google).
// GET /api/ytsearch?q=pregação&t=video|short
// Só vídeos que PODEM tocar fora do YouTube, conteúdo seguro (safeSearch strict), em português / Brasil.
// Cada busca igual fica guardada 24 horas, para gastar pouco da cota grátis (10.000 unidades por dia = ~100 buscas novas).
const CACHE_SEC = 24 * 3600;
const json = (d, s = 200, cache = 0) => new Response(JSON.stringify(d), { status: s, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': cache ? `public, max-age=${cache}` : 'no-store' } });
const unesc = t => String(t || '').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>');

export async function onRequestGet({ request, env, waitUntil }) {
  const url = new URL(request.url);
  const q = (url.searchParams.get('q') || '').trim().replace(/\s+/g, ' ').slice(0, 80);
  const t = url.searchParams.get('t') === 'short' ? 'short' : 'video';
  if (q.length < 2) return json({ error: 'q' }, 400);
  if (!env.YT_API_KEY) return json({ error: 'config' }, 200);
  const cache = caches.default;
  const key = new Request(`https://tocaplay-cache/yts/${t}/${encodeURIComponent(q.toLowerCase())}`);
  const hit = await cache.match(key);
  if (hit) return new Response(hit.body, hit);
  const p = new URLSearchParams({
    part: 'snippet', type: 'video', q, maxResults: '24', regionCode: 'BR', relevanceLanguage: 'pt',
    safeSearch: 'strict', videoEmbeddable: 'true', videoSyndicated: 'true', key: env.YT_API_KEY
  });
  if (t === 'short') p.set('videoDuration', 'short');
  let r;
  try { r = await fetch('https://www.googleapis.com/youtube/v3/search?' + p); } catch { return json({ error: 'rede' }, 502); }
  if (r.status === 403) return json({ error: 'cota' }, 200);   // cota do dia acabou: o app usa só a busca interna
  if (!r.ok) return json({ error: 'yt', status: r.status }, 200);
  const d = await r.json();
  const items = (d.items || []).filter(i => i.id && i.id.videoId && i.snippet && i.snippet.liveBroadcastContent !== 'upcoming').map(i => ({
    id: i.id.videoId, title: unesc(i.snippet.title), ch: unesc(i.snippet.channelTitle), cid: i.snippet.channelId,
    live: i.snippet.liveBroadcastContent === 'live'
  }));
  const resp = json({ items }, 200, CACHE_SEC);
  waitUntil(cache.put(key, resp.clone()));
  return resp;
}
