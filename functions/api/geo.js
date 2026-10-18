// Cloudflare Pages: devolve só cidade e estado aproximados (sem IP, por causa da LGPD).
export function onRequest(context) {
  const c = context.request.cf || {};
  const body = {
    city: c.city || null,
    region: c.region || null,
    regionCode: c.regionCode || null,
    country: c.country || null
  };
  return new Response(JSON.stringify(body), {
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' }
  });
}
