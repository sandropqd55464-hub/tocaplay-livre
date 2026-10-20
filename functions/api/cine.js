// Cloudflare Pages: "Cinema livre" — filmes em domínio público / licença livre do Internet Archive (archive.org),
// que permite tocar dentro de outros sites pelo player oficial (archive.org/embed/...).
// GET /api/cine?s=classicos|nacionais|animacao|terror|faroeste  -> {filmes:[{id,titulo,ano,img}]}
const CACHE_SEC = 24 * 3600;
const Q = {
  classicos: 'collection:(feature_films) AND mediatype:(movies)',
  nacionais: 'mediatype:(movies) AND (language:(Portuguese) OR language:(por) OR subject:(brasil) OR subject:(brazil) OR subject:("cinema brasileiro"))',
  animacao:  'collection:(classic_cartoons) AND mediatype:(movies)',
  terror:    'collection:(feature_films) AND mediatype:(movies) AND subject:(horror)',
  faroeste:  'collection:(feature_films) AND mediatype:(movies) AND subject:(western)',
  comedia:   'collection:(feature_films) AND mediatype:(movies) AND subject:(comedy)'
};

async function busca(s) {
  const q = Q[s];
  const p = new URLSearchParams({ q: q + ' AND -access-restricted-item:(true)', rows: '60', output: 'json', page: '1' });
  ['identifier', 'title', 'year'].forEach(f => p.append('fl[]', f));
  p.append('sort[]', 'downloads desc');
  const r = await fetch('https://archive.org/advancedsearch.php?' + p.toString(), { headers: { 'user-agent': 'TocaPlayLivre/1.0 (+https://tocaplaylivre.com.br)' } });
  if (!r.ok) return [];
  const d = await r.json();
  return ((d.response && d.response.docs) || [])
    .filter(x => x.identifier && x.title)
    .map(x => ({ id: x.identifier, titulo: Array.isArray(x.title) ? x.title[0] : String(x.title), ano: x.year ? String(x.year).slice(0, 4) : '', img: `https://archive.org/services/img/${x.identifier}` }));
}

export async function onRequest(context) {
  const url = new URL(context.request.url);
  const s = url.searchParams.get('s') || 'classicos';
  if (!Q[s]) return new Response('{"error":"secao"}', { status: 400, headers: { 'content-type': 'application/json' } });
  const cache = caches.default, key = new Request(`https://tocaplay-cache/cine/${s}`);
  const hit = await cache.match(key);
  if (hit) return new Response(hit.body, { headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'public, max-age=3600' } });
  let filmes = [];
  try { filmes = await busca(s); } catch {}
  const body = JSON.stringify({ filmes });
  if (filmes.length) context.waitUntil(cache.put(key, new Response(body, { headers: { 'content-type': 'application/json', 'cache-control': `public, max-age=${CACHE_SEC}` } })));
  return new Response(body, { headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'public, max-age=600' } });
}
