// Devolve só a cidade e o estado aproximados de quem abriu o site (dados do próprio Netlify).
// Não guarda nada aqui e não devolve o endereço de internet (IP), por causa da LGPD.
export default (request, context) => {
  const g = context.geo || {};
  const body = {
    city: g.city || null,
    region: (g.subdivision && g.subdivision.name) || null,
    regionCode: (g.subdivision && g.subdivision.code) || null,
    country: (g.country && g.country.code) || null
  };
  return new Response(JSON.stringify(body), {
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' }
  });
};

export const config = { path: '/api/geo' };
