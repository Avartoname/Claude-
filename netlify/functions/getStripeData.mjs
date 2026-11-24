// Stripe summary for the HQ dashboard (replaces the Base44 backend function of the same name).
// Env vars (Netlify): STRIPE_SECRET_KEY (a restricted read-only key is enough), SUPABASE_URL, SUPABASE_ANON_KEY.
// Only signed-in HQ owners / Ops Managers can call it.
const json = (o, status = 200) => new Response(JSON.stringify(o), { status, headers: { 'Content-Type': 'application/json' } });

async function hqRole(authHeader) {
  const SB = process.env.SUPABASE_URL, ANON = process.env.SUPABASE_ANON_KEY;
  if (!SB || !ANON || !authHeader) return null;
  const h = { Authorization: authHeader, apikey: ANON };
  const u = await fetch(`${SB}/auth/v1/user`, { headers: h });
  if (!u.ok) return null;
  const { id } = await u.json();
  const p = await fetch(`${SB}/rest/v1/hq_profiles?select=role,active&id=eq.${encodeURIComponent(id)}`, { headers: h });
  const rows = p.ok ? await p.json() : [];
  return rows[0]?.active ? rows[0].role : null;
}

async function stripe(path, key) {
  const r = await fetch(`https://api.stripe.com/v1/${path}`, { headers: { Authorization: `Bearer ${key}` } });
  const j = await r.json();
  if (!r.ok) throw new Error(j?.error?.message || `Stripe ${r.status}`);
  return j;
}

export default async (req) => {
  const role = await hqRole(req.headers.get('authorization'));
  if (!role) return json({ error: 'Sign in to view Stripe data.' }, 401);
  if (!['owner', 'ops'].includes(role)) return json({ error: 'Stripe data is visible to the owner and Ops Managers only.' }, 403);
  const KEY = process.env.STRIPE_SECRET_KEY;
  if (!KEY) return json({ error: 'Stripe not connected — add STRIPE_SECRET_KEY in Netlify.' });
  try {
    const since = Math.floor(Date.now() / 1000) - 30 * 86400;
    let charges = [], starting_after = null;
    for (let i = 0; i < 10; i++) {
      const page = await stripe(`charges?limit=100&created[gte]=${since}${starting_after ? `&starting_after=${starting_after}` : ''}`, KEY);
      charges = charges.concat(page.data);
      if (!page.has_more) break;
      starting_after = page.data[page.data.length - 1].id;
    }
    const paid = charges.filter((c) => c.paid && c.status === 'succeeded' && c.currency === 'gbp');
    const balance = await stripe('balance', KEY);
    const gbp = (arr) => (arr || []).filter((b) => b.currency === 'gbp').reduce((s, b) => s + b.amount, 0);
    return json({
      total_30_days: paid.reduce((s, c) => s + c.amount - (c.amount_refunded || 0), 0),
      count_30_days: paid.length,
      available: gbp(balance.available),
      pending: gbp(balance.pending),
      recent_payments: paid.slice(0, 6).map((c) => ({
        id: c.id, amount: c.amount, created: c.created,
        customer_email: c.billing_details?.email || c.receipt_email || null,
        metadata: c.metadata || {},
      })),
    });
  } catch (e) {
    return json({ error: `Stripe: ${e.message}` });
  }
};
