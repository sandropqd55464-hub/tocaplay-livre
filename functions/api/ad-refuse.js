// Recusar anúncio (só o dono do TocaPlay): devolve o dinheiro pelo Mercado Pago e marca como recusado
import { whoIs, db, mp, json, OWNER } from './_ads.js';
export async function onRequestPost({ request, env }) {
  const user = await whoIs(request);
  if (!user || String(user.email).toLowerCase() !== OWNER) return json({ error: 'acesso' }, 403);
  let body = {}; try { body = await request.json(); } catch {}
  const id = parseInt(body.id, 10); if (!id) return json({ error: 'id' }, 400);
  const [ad] = await db(env, `ads?id=eq.${id}&select=*`);
  if (!ad || ad.status !== 'em_analise') return json({ error: 'status' }, 409);
  let devolvido = false;
  if (ad.mp_payment) {
    try { await mp(env, `/v1/payments/${ad.mp_payment}/refunds`, { method: 'POST', headers: { 'X-Idempotency-Key': `refund-ad-${ad.id}` }, body: '{}' }); devolvido = true; }
    catch (e) { return json({ error: 'estorno', detail: String(e.message).slice(0, 160) }, 502); }
  }
  await db(env, `ads?id=eq.${id}`, { method: 'PATCH', body: JSON.stringify({ status: 'recusado' }) });
  return json({ ok: true, devolvido });
}
