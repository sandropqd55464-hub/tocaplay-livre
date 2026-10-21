// Funções de apoio para os anúncios (não é um endereço público: começa com "_")
export const SB_URL = 'https://odyrlnniwwefdwspzlch.supabase.co';
export const SB_ANON = 'sb_publishable_vjFTbDiH7vbS047zvZsOCQ_gtbTIIcE';
export const OWNER = 'sandropqd55464@gmail.com';
export const json = (d, s = 200) => new Response(JSON.stringify(d), { status: s, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' } });

// Confere quem está pedindo (pelo login do Supabase)
export async function whoIs(request) {
  const auth = request.headers.get('authorization') || '';
  if (!auth.startsWith('Bearer ')) return null;
  const r = await fetch(`${SB_URL}/auth/v1/user`, { headers: { apikey: SB_ANON, authorization: auth } });
  if (!r.ok) return null;
  return r.json();
}
// Banco com a chave secreta (fica só no servidor da Cloudflare, nunca no site)
export async function db(env, path, opts = {}) {
  const r = await fetch(`${SB_URL}/rest/v1/${path}`, {
    ...opts,
    headers: { apikey: env.SUPABASE_SECRET_KEY, 'content-type': 'application/json', prefer: 'return=representation', ...(opts.headers || {}) }
  });
  const t = await r.text();
  if (!r.ok) throw new Error(`db ${r.status}: ${t.slice(0, 200)}`);
  return t ? JSON.parse(t) : null;
}
export async function mp(env, path, opts = {}) {
  const r = await fetch(`https://api.mercadopago.com${path}`, {
    ...opts,
    headers: { authorization: `Bearer ${env.MP_ACCESS_TOKEN}`, 'content-type': 'application/json', ...(opts.headers || {}) }
  });
  const t = await r.text();
  if (!r.ok) throw new Error(`mp ${r.status}: ${t.slice(0, 200)}`);
  return t ? JSON.parse(t) : null;
}
