// Cloudflare Pages: devolve só cidade e estado aproximados (sem IP, por causa da LGPD).
// "dc" avisa quando o acesso vem de um servidor de nuvem (robôs), para não contar como visitante.
const DATACENTER = /amazon|aws|google|microsoft|azure|digitalocean|ovh|hetzner|linode|akamai|oracle|alibaba|tencent|vultr|choopa|contabo|leaseweb|m247|scaleway|cloudflare|facebook|meta platforms|datacamp|hostinger|ionos|zenlayer|psychz|colocrossing|servers\.com|hostroyale|g-core|gcore/i;
// Redes (ASN) de empresas de nuvem e hospedagem: Amazon, Google, Microsoft, Oracle, OVH, Hetzner, DigitalOcean, Linode, Vultr, Alibaba, Tencent, Contabo, Scaleway, Leaseweb, M247, IONOS, Hostinger...
const DC_ASN = new Set([16509, 14618, 8987, 15169, 396982, 19527, 36040, 8075, 8068, 31898, 16276, 24940, 213230, 14061, 63949, 20473, 45102, 37963, 132203, 45090, 51167, 12876, 16125, 60781, 28753, 9009, 8560, 47583, 22612, 46606, 26496, 36352, 55286, 40021, 62567, 212238, 202425, 49981, 23470, 30633, 54290, 35916, 398101, 7203, 25820, 20454, 62240, 136907, 211252]);
export function onRequest(context) {
  const c = context.request.cf || {};
  const org = String(c.asOrganization || '');
  const body = {
    city: c.city || null,
    region: c.region || null,
    regionCode: c.regionCode || null,
    country: c.country || null,
    dc: DATACENTER.test(org) || DC_ASN.has(+c.asn)
  };
  return new Response(JSON.stringify(body), {
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' }
  });
}
