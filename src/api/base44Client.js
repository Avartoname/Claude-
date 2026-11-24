// Supabase-backed replacement for the old Base44 client.
// Keeps the same `base44.entities.X.list(...)`, `base44.auth.*` and `base44.functions.invoke(...)`
// shape so existing pages work unchanged. Data comes from Supabase views named app_* (see
// supabase/migrations/0005_tppg_app_views.sql), which apply the same row-level security as the hq_ tables.
import { supabase } from './supabaseClient';

// Entity name → Supabase view
const ENTITY_VIEWS = {
  Booking: 'app_bookings',
  Party: 'app_parties',
  InventoryItem: 'app_inventory',
  Review: 'app_reviews',
  StaffMember: 'app_staff',
  PosSale: 'app_pos_sales',
};

// HQ roles in Supabase → roles the app's navigation understands (src/lib/roleAccess.js)
const ROLE_MAP = { owner: 'admin', ops: 'manager', lead: 'team leader', staff: 'assistant' };

const fail = (error) => {
  const e = new Error(error?.message || 'Request failed');
  e.status = error?.status || (error?.code === '42501' ? 403 : 500);
  e.data = error;
  throw e;
};

function entity(name) {
  const view = ENTITY_VIEWS[name];
  const ensure = () => { if (!view) throw new Error(`Entity "${name}" is not mapped to a Supabase view yet`); };
  const order = (q, sort) => {
    if (!sort) return q;
    const desc = sort.startsWith('-');
    return q.order(desc ? sort.slice(1) : sort, { ascending: !desc, nullsFirst: false });
  };
  return {
    async list(sort, limit) {
      ensure();
      let q = order(supabase.from(view).select('*'), sort);
      if (limit) q = q.limit(limit);
      const { data, error } = await q;
      if (error) fail(error);
      return data || [];
    },
    async filter(where = {}, sort, limit) {
      ensure();
      let q = supabase.from(view).select('*');
      Object.entries(where).forEach(([k, v]) => { q = q.eq(k, v); });
      q = order(q, sort);
      if (limit) q = q.limit(limit);
      const { data, error } = await q;
      if (error) fail(error);
      return data || [];
    },
    async get(id) {
      ensure();
      const { data, error } = await supabase.from(view).select('*').eq('id', id).maybeSingle();
      if (error) fail(error);
      return data;
    },
  };
}

async function me() {
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) { const e = new Error('Authentication required'); e.status = 401; throw e; }
  const { data: profile, error: pErr } = await supabase
    .from('hq_profiles').select('full_name, role, venue_id, active').eq('id', user.id).maybeSingle();
  if (pErr) fail(pErr);
  if (!profile || !profile.active) {
    const e = new Error('User not registered for this app');
    e.status = 403; e.data = { extra_data: { reason: 'user_not_registered' } };
    throw e;
  }
  return {
    id: user.id,
    email: user.email,
    full_name: profile.full_name || user.user_metadata?.full_name || user.email,
    role: ROLE_MAP[profile.role] || 'user',
    hq_role: profile.role,
    venue_id: profile.venue_id,
  };
}

export const base44 = {
  entities: new Proxy({}, { get: (_, name) => entity(String(name)) }),
  auth: {
    me,
    async logout(redirectTo) {
      await supabase.auth.signOut();
      window.location.assign('/login');
    },
    redirectToLogin(fromUrl) {
      const next = fromUrl ? new URL(fromUrl, window.location.origin).pathname : '/';
      window.location.assign(`/login?next=${encodeURIComponent(next)}`);
    },
  },
  functions: {
    // Netlify Functions (netlify/functions/<name>.mjs); sends the signed-in user's token
    async invoke(name, body = {}) {
      const { data: { session } } = await supabase.auth.getSession();
      const res = await fetch(`/.netlify/functions/${encodeURIComponent(name)}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...(session ? { Authorization: `Bearer ${session.access_token}` } : {}) },
        body: JSON.stringify(body),
      });
      let data = null;
      try { data = await res.json(); } catch { data = { error: `Function ${name} returned ${res.status}` }; }
      if (!res.ok && data && !data.error) data.error = `Function ${name} returned ${res.status}`;
      return { data, status: res.status };
    },
  },
};
