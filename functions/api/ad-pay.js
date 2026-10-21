// Cria o pagamento no Mercado Pago (Pix ou cartão) para um anúncio do próprio usuário
import { whoIs, db, mp, json } from './_ads.js';
export async function onRequestPost({ request, env }) {
  if (!env.MP_ACCESS_TOKEN || !env.SUPABASE_SECRET_KEY) return json({ error: 'config' }, 500);
  const user = await whoIs(request); if (!user) return json({ error: 'login' }, 401);
  let body = {}; try { body = await request.json(); } catch {}
  const id = parseInt(body.id, 10); if (!id) return json({ error: 'id' }, 400);
  const [ad] = await db(env, `ads?id=eq.${id}&select=*`);
  if (!ad || ad.user_id !== user.id) return json({ error: 'nao_encontrado' }, 404);
  if (ad.status !== 'aguardando_pagamento') return json({ error: 'ja_pago' }, 409);
  const origin = new URL(request.url).origin;
  const pref = await mp(env, '/checkout/preferences', { method: 'POST', body: JSON.stringify({
    items: [{ id: String(ad.id), title: `Anúncio TocaPlay - ${ad.days} dia${ad.days > 1 ? 's' : ''}`, description: ad.title, quantity: 1, currency_id: 'BRL', unit_price: Number(ad.price) }],
    payer: { email: user.email },
    external_reference: String(ad.id),
    notification_url: `${origin}/api/mp-webhook`,
    back_urls: { success: `${origin}/anunciar.html#pago`, pending: `${origin}/anunciar.html#pendente`, failure: `${origin}/anunciar.html#falhou` },
    auto_return: 'approved',
    statement_descriptor: 'TOCAPLAY',
    payment_methods: { installments: 1 }
  }) });
  await db(env, `ads?id=eq.${ad.id}`, { method: 'PATCH', body: JSON.stringify({ mp_pref: pref.id }) });
  return json({ url: pref.init_point });
}
