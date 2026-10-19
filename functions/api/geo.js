// Cloudflare Pages: devolve só cidade e estado aproximados (sem IP, por causa da LGPD).
// "dc" avisa quando o acesso vem de um servidor de nuvem (robôs), para não contar como visitante.
const DATACENTER = /amazon|aws|google|microsoft|azure|digitalocean|ovh|hetzner|linode|akamai|oracle|alibaba|tencent|vultr|choopa|contabo|leaseweb|m247|scaleway|cloudflare|facebook|meta platforms|datacamp|hostinger|ionos|zenlayer|psychz|colocrossing|servers\.com|hostroyale|g-core|gcore/i;
export function onRequest(context) {
  const c = context.request.cf || {};
  const org = String(c.asOrganization || '');
  const body = {
    city: c.city || null,
    region: c.region || null,
    regionCode: c.regionCode || null,
    country: c.country || null,
    dc: DATACENTER.test(org)
  };
  return new Response(JSON.stringify(body), {
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' }
  });
}
