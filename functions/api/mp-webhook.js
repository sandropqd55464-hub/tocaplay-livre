// Aviso do Mercado Pago: confere o pagamento direto na API do Mercado Pago (não confia no aviso) e libera o anúncio
import { db, mp, json } from './_ads.js';
export async function onRequest({ request, env }) {
  try {
    const url = new URL(request.url);
    let body = {}; try { body = await request.json(); } catch {}
    const type = body.type || url.searchParams.get('type') || url.searchParams.get('topic');
    const pid = (body.data && body.data.id) || url.searchParams.get('data.id') || url.searchParams.get('id');
    if (type !== 'payment' || !pid) return json({ ok: true });
    const pay = await mp(env, `/v1/payments/${encodeURIComponent(pid)}`);
    const adId = parseInt(pay.external_reference, 10);
    if (!adId || pay.status !== 'approved') return json({ ok: true });
    const [ad] = await db(env, `ads?id=eq.${adId}&select=*`);
    if (!ad || ad.status !== 'aguardando_pagamento') return json({ ok: true });
    if (Number(pay.transaction_amount) + 0.001 < Number(ad.price)) return json({ ok: true });   // valor diferente: não libera
    const start = new Date(Math.max(Date.parse(ad.start_at), Date.now()));
    const patch = { mp_payment: String(pay.id), paid: pay.transaction_amount, paid_at: new Date().toISOString() };
    if (ad.renew_of) {   // renovação: imagem já aprovada antes, entra no ar sozinha
      patch.status = 'aprovado'; patch.start_at = start.toISOString(); patch.end_at = new Date(start.getTime() + ad.days * 864e5).toISOString();
    } else patch.status = 'em_analise';
    await db(env, `ads?id=eq.${adId}&status=eq.aguardando_pagamento`, { method: 'PATCH', body: JSON.stringify(patch) });
    return json({ ok: true });
  } catch (e) { return json({ ok: false, error: String(e.message || e).slice(0, 120) }, 200); }
}
