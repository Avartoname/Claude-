// The Paint Patch HQ — Outlook feed (Supabase Edge Function, runs every 5 minutes)
// Reads the bookings mailbox through Microsoft Graph (read-only) and writes to Supabase:
//   • ROLLER "Order Confirmation" emails → hq_roller_emails → hq_bookings (via trigger)
//   • Customer emails → hq_threads / hq_messages with customer-service triage + reply deadlines
//   • Complaints, refunds, safety, legal → hq_complaints (with the email as evidence)
//   • Replies sent from Outlook (Sent Items) → marks the thread replied, records response time
//   • Overdue replies → hq_tasks (once per thread)
// Secrets (Edge Functions → Secrets): MS_TENANT_ID, MS_CLIENT_ID, MS_CLIENT_SECRET, MS_MAILBOX, CRON_SECRET
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase automatically.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const env = (k: string) => Deno.env.get(k) ?? "";
const sb = createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), { auth: { persistSession: false } });
const MAILBOX = env("MS_MAILBOX") || "bookings@thepaintpatch.com";
const GRAPH = "https://graph.microsoft.com/v1.0";

// ---------- helpers ----------
async function token(): Promise<string> {
  const r = await fetch(`https://login.microsoftonline.com/${env("MS_TENANT_ID")}/oauth2/v2.0/token`, {
    method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ client_id: env("MS_CLIENT_ID"), client_secret: env("MS_CLIENT_SECRET"), scope: "https://graph.microsoft.com/.default", grant_type: "client_credentials" }),
  });
  const j = await r.json(); if (!j.access_token) throw new Error("Microsoft sign-in failed: " + (j.error_description || j.error || r.status));
  return j.access_token;
}
async function graphAll(tok: string, url: string, max = 200): Promise<any[]> {
  const out: any[] = []; let next: string | null = url;
  while (next && out.length < max) {
    const r = await fetch(next, { headers: { Authorization: `Bearer ${tok}`, Prefer: 'outlook.body-content-type="html"' } });
    if (!r.ok) throw new Error(`Graph ${r.status}: ${(await r.text()).slice(0, 200)}`);
    const j = await r.json(); out.push(...(j.value || [])); next = j["@odata.nextLink"] || null;
  }
  return out;
}
const setting = async (key: string, fallback: string) => { const { data } = await sb.from("hq_settings").select("value").eq("key", key).maybeSingle(); return (data?.value as string) ?? fallback; };
const saveSetting = (key: string, value: unknown) => sb.from("hq_settings").upsert({ key, value, updated_at: new Date().toISOString() });
const log = (action: string, detail = "", level = "info", venue_id: string | null = null, ref?: { type: string; id: string }) =>
  sb.from("hq_activity_log").insert({ actor_name: "Outlook feed", automated: true, action, detail, level, venue_id, ref_type: ref?.type ?? null, ref_id: ref?.id ?? null });

export const htmlToText = (h: string) => String(h || "")
  .replace(/<(script|style)[\s\S]*?<\/\1>/gi, "").replace(/<br\s*\/?>/gi, "\n").replace(/<\/(p|div|tr|li|h\d)>/gi, "\n")
  .replace(/<[^>]+>/g, " ").replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&#39;|&rsquo;/g, "'").replace(/&quot;/g, '"')
  .replace(/[ \t]+/g, " ").replace(/\n\s*\n+/g, "\n").trim();
const stripQuoted = (t: string) => t.split(/\n(?:On .{5,80} wrote:|From: .+\n(?:Sent|Date): |-{2,} ?Original Message|_{10,})/i)[0].trim();
const venueOf = (t: string) => /hatfield|galleria/i.test(t) ? "hat" : /milton keynes|xscape|\bMK\b/i.test(t) ? "mk" : null;
const skipSender = (email: string, subject: string) => /no-?reply|notifications?@|mailer-daemon|postmaster|newsletter|marketing@|updates@|bounce/i.test(email) ||
  (/@thepaintpatch\.com$/i.test(email) && !/^website contact/i.test(subject || ""));

// ---------- ROLLER order emails ----------
const MON: Record<string, number> = { jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6, jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12 };
const rDate = (s: string) => { const m = String(s || "").match(/(\w{3})\s+(\d{1,2})\s+(\d{4})/); return m && MON[m[1].toLowerCase()] ? `${m[3]}-${String(MON[m[1].toLowerCase()]).padStart(2, "0")}-${m[2].padStart(2, "0")}` : null; };
const rTime = (s: string) => { const m = String(s || "").match(/(\d{1,2}):(\d{2})\s*([AP]M)/i); if (!m) return null; const hh = (+m[1] % 12) + (/p/i.test(m[3]) ? 12 : 0); return `${String(hh).padStart(2, "0")}:${m[2]}`; };
export function parseRoller(subject: string, html: string) {
  const t = htmlToText(html);
  const ref = (html.match(/booking(?:%2F|\/)(\d{6,})/i) || [])[1] || null;
  const lines: any[] = []; const re = /(\d+)\s*x\s*(.+?)\s+-\s+(.+?)\s+(\d{1,2}:\d{2}\s*[AP]M)\s*-\s*(\d{1,2}:\d{2}\s*[AP]M)\s+(\w{3}\s+\w{3}\s+\d{1,2}\s+\d{4})/gi; let m;
  while ((m = re.exec(t))) lines.push({ qty: +m[1], product: m[2].trim(), ticket: m[3].trim(), start: rTime(m[4]), end: rTime(m[5]), date: rDate(m[6]) });
  const sec = ((t.split(/Booking details:/i)[1] || "").split(/Booking total:/i)[0] || "");
  const extras = sec.split("\n").map((x) => x.trim()).filter((x) => /^\d+\s*x\s+/i.test(x) && !/\d{1,2}:\d{2}\s*[AP]M/i.test(x)).map((x) => { const q = x.match(/^(\d+)\s*x\s+(.+)$/i)!; return { qty: +q[1], product: q[2].trim() }; });
  const total = (t.match(/Booking total:\s*£\s*([\d,]+(?:\.\d{2})?)/i) || [])[1];
  const pur = (t.split(/Purchaser details:/i)[1] || "").split("\n").map((x) => x.trim()).filter(Boolean).slice(0, 4);
  const email = pur.find((x) => /@/.test(x)) || null, phone = pur.find((x) => /^\+?\d[\d\s]{8,}$/.test(x)) || null;
  const name = pur.find((x) => x !== email && x !== phone && !/learn roller|support/i.test(x)) || null;
  const f = lines[0] || {};
  return { ref, venue: venueOf(subject), lines, extras, total: total ? +total.replace(/,/g, "") : null, date: f.date || rDate((t.match(/Booking date:\s*(.+)/i) || [])[1] || ""),
    time: f.start || null, end: f.end || null, product: f.product || extras[0]?.product || subject.replace(/^.*? - /, ""),
    guests: lines.filter((l) => l.date === f.date && l.start === f.start).reduce((a, l) => a + l.qty, 0) || null, customer: { name, email, phone } };
}

// ---------- customer-service triage ----------
const RULES: [string, RegExp][] = [
  ["safety", /\b(injur\w*|hurt|accident|bleed\w*|allergic reaction|hospital|a ?& ?e|burn(t|ed)?|slipped|fell over|safeguard\w*|unsafe|in (his|her|their) eyes?)\b/i],
  ["legal", /\b(solicitor|legal action|small claims|trading standards|charge ?back|ombudsman|sue\b)/i],
  ["complaint", /\b(complain\w*|disappoint\w*|unhappy|not happy|appall\w*|disgust\w*|unacceptable|terrible|awful|rude|ruin(ed)?|stain(ed)?|damaged|worst|let down|furious|upset|(1|one)[- ]?star|bad review|not (been )?(delivered|received)|never (arrived|received)|half[- ]painted|mislabel\w*)\b/i],
  ["refund", /\b(refund\w*|money back|charged twice|double charged|overcharged|reimburse\w*|compensat\w*)\b/i],
  ["chasing", /\b(still waiting|still not heard|haven'?t heard|no (reply|response)|chasing|second time|third time|following up|any update)\b/i],
];
export function triage(text: string) {
  const sig = RULES.filter(([, r]) => r.test(text)).map(([k]) => k);
  const cat = ["safety", "legal", "complaint", "refund", "chasing"].find((c) => sig.includes(c)) || "service";
  const pri = ["safety", "legal"].includes(cat) ? "high" : cat === "service" ? "low" : "medium";
  return { cat, pri, sig };
}
const cxCategory = (cat: string, text: string) => cat === "safety" ? "safety" : cat === "refund" ? "refund"
  : /bear|canvas|artwork|painting|t-?shirt|collect|post(age|ed)|deliver/i.test(text) ? "artwork"
  : /book(ing|ed)|double|time slot|wait(ed|ing)/i.test(text) ? "booking" : /staff|rude|host/i.test(text) ? "staff" : "other";
const cxSeverity: Record<string, string> = { safety: "critical", legal: "critical", complaint: "high", refund: "medium" };

// ---------- main ----------
Deno.serve(async (req) => {
  if (env("CRON_SECRET") && req.headers.get("x-cron-secret") !== env("CRON_SECRET")) return new Response("forbidden", { status: 403 });
  const started = new Date().toISOString(); const stats = { bookings: 0, emails: 0, complaints: 0, replies: 0, overdue: 0 };
  try {
    const tok = await token();
    const since = await setting("outlook_since", new Date(Date.now() - 60 * 864e5).toISOString());
    const sentSince = await setting("outlook_sent_since", since);
    const sel = "id,subject,from,receivedDateTime,body,conversationId,webLink";
    const inbox = await graphAll(tok, `${GRAPH}/users/${MAILBOX}/mailFolders/inbox/messages?$filter=receivedDateTime ge ${since}&$orderby=receivedDateTime asc&$top=50&$select=${sel}`);

    for (const m of inbox) {
      const from = (m.from?.emailAddress?.address || "").toLowerCase(), fromName = m.from?.emailAddress?.name || from, subject = m.subject || "(no subject)";
      const html = m.body?.content || "";
      // 1. ROLLER bookings
      if (/@roller\.app$/.test(from) && /^order confirmation/i.test(subject)) {
        const p = parseRoller(subject, html);
        const { error } = await sb.from("hq_roller_emails").upsert({ outlook_id: m.id, received_at: m.receivedDateTime, subject, parsed: p, web_link: m.webLink }, { onConflict: "outlook_id", ignoreDuplicates: true });
        if (!error) stats.bookings++;
        continue;
      }
      if (skipSender(from, subject)) continue;
      // 2. Customer emails (website contact form → the real customer)
      let body = stripQuoted(htmlToText(html)), custName = fromName, custEmail = from, replyTo: string | null = null;
      if (/^website contact/i.test(subject)) {
        const g = (re: RegExp) => (body.match(re) || [])[1]?.trim() || "";
        const e = g(/Email:\s*(\S+@\S+)/i); if (e) { custEmail = e.toLowerCase(); replyTo = custEmail; custName = g(/Name:\s*(.+)/i) || custEmail; body = g(/Message:\s*([\s\S]+)/i) || body; }
      }
      if (/^job application/i.test(subject)) continue; // HR applications are handled in HQ, not as customer service
      const { data: dupe } = await sb.from("hq_messages").select("id").eq("outlook_message_id", m.id).maybeSingle(); if (dupe) continue;
      const convo = replyTo ? `${m.conversationId}:${replyTo}` : m.conversationId;
      let { data: th } = await sb.from("hq_threads").select("*").eq("outlook_conversation_id", convo).maybeSingle();
      const venue = venueOf(`${subject}\n${body}`);
      if (!th) {
        const ins = await sb.from("hq_threads").insert({ outlook_conversation_id: convo, venue_id: venue, from_name: custName, from_email: custEmail, reply_to: replyTo, subject, state: "new", outlook_web_link: m.webLink }).select().single();
        th = ins.data; if (!th) continue;
      }
      await sb.from("hq_messages").insert({ thread_id: th.id, direction: "in", outlook_message_id: m.id, body: body.slice(0, 20000), sent_at: m.receivedDateTime });
      stats.emails++;
      // triage over the whole conversation
      const { data: msgs } = await sb.from("hq_messages").select("body,direction").eq("thread_id", th.id);
      const allIn = `${subject}\n${(msgs || []).filter((x: any) => x.direction === "in").map((x: any) => x.body).join("\n")}`;
      const t = triage(allIn);
      await sb.from("hq_threads").update({ category: t.cat, cs_category: t.cat, cs_priority: t.pri, cs_signals: t.sig, cs_since: m.receivedDateTime, cs_status: "waiting", cs_replied_at: null, cs_response_hours: null, venue_id: th.venue_id || venue, outlook_web_link: m.webLink, updated_at: new Date().toISOString() }).eq("id", th.id);
      // complaint register (once per thread)
      if (["safety", "legal", "complaint", "refund"].includes(t.cat)) {
        const { data: existing } = await sb.from("hq_complaints").select("id").eq("thread_id", th.id).maybeSingle();
        if (!existing) {
          const { data: cx } = await sb.from("hq_complaints").insert({ kind: "complaint", customer_name: custName, customer_email: custEmail, venue_id: th.venue_id || venue, received_at: m.receivedDateTime,
            category: cxCategory(t.cat, allIn), severity: cxSeverity[t.cat], description: `${subject} — ${body.replace(/\s+/g, " ").slice(0, 600)}`, next_action: "Acknowledge the customer and assign an owner",
            refund_requested: null, verified: true, source: "outlook", thread_id: th.id }).select("id,ref").single();
          if (cx) { stats.complaints++; await sb.from("hq_complaint_evidence").insert({ complaint_id: cx.id, kind: "email", url: m.webLink, note: subject });
            await sb.from("hq_complaint_events").insert({ complaint_id: cx.id, event: "received", detail: `From Outlook: ${subject}` });
            await log("Complaint logged", `${cx.ref} · ${custName} · ${t.cat}`, t.pri === "high" ? "warn" : "info", th.venue_id || venue, { type: "complaint", id: cx.id }); }
        }
      }
    }

    // 3. Replies sent from Outlook
    const sent = await graphAll(tok, `${GRAPH}/users/${MAILBOX}/mailFolders/sentitems/messages?$filter=sentDateTime ge ${sentSince}&$orderby=sentDateTime asc&$top=50&$select=id,subject,toRecipients,conversationId,sentDateTime,webLink`);
    for (const s of sent) {
      const { data: dupe } = await sb.from("hq_messages").select("id").eq("outlook_message_id", s.id).maybeSingle(); if (dupe) continue;
      const tos = (s.toRecipients || []).map((r: any) => (r.emailAddress?.address || "").toLowerCase()).filter(Boolean);
      let { data: th } = await sb.from("hq_threads").select("id,cs_since,venue_id").eq("outlook_conversation_id", s.conversationId).maybeSingle();
      if (!th && tos.length) { const r = await sb.from("hq_threads").select("id,cs_since,venue_id").or(tos.map((e: string) => `from_email.eq.${e},reply_to.eq.${e}`).join(",")).order("updated_at", { ascending: false }).limit(1); th = r.data?.[0] || null; }
      if (!th || (th.cs_since && th.cs_since > s.sentDateTime)) continue;
      await sb.from("hq_messages").insert({ thread_id: th.id, direction: "out", outlook_message_id: s.id, body: `(Replied in Outlook) ${s.subject || ""}`, sent_at: s.sentDateTime, via_outlook_sent: true });
      await sb.from("hq_threads").update({ cs_replied_at: s.sentDateTime, state: "replied", updated_at: new Date().toISOString() }).eq("id", th.id);
      await sb.from("hq_complaints").update({ acknowledged_at: s.sentDateTime }).eq("thread_id", th.id).is("acknowledged_at", null);
      stats.replies++;
    }

    // 4. Overdue replies → one task each (high priority to the owner's queue; others to the venue)
    const { data: over } = await sb.from("hq_threads").select("id,from_name,cs_category,cs_priority,cs_since,venue_id").eq("cs_status", "waiting").lt("cs_due_at", new Date().toISOString()).neq("cs_priority", "low");
    for (const t of over || []) {
      const { error } = await sb.from("hq_tasks").insert({ title: `Overdue reply: ${t.cs_category} from ${t.from_name}`, kind: "follow-up", venue_id: t.venue_id, due_date: new Date().toISOString().slice(0, 10), ref_type: "thread", ref_id: t.id, idem_key: `csover:${t.id}:${t.cs_since}` });
      if (!error) stats.overdue++;
    }

    await saveSetting("outlook_since", inbox.length ? inbox[inbox.length - 1].receivedDateTime : since);
    await saveSetting("outlook_sent_since", sent.length ? sent[sent.length - 1].sentDateTime : sentSince);
    await sb.from("hq_integrations").upsert({ id: "outlook", name: "Outlook (bookings mailbox)", status: "connected", last_sync: started, note: `Feed OK · ${JSON.stringify(stats)}` });
    await sb.from("hq_integrations").upsert({ id: "roller", name: "ROLLER", status: "connected", last_sync: started, note: "Bookings read from ROLLER order emails in Outlook (no availability data)" });
    if (stats.bookings || stats.emails || stats.replies || stats.complaints) await log("Outlook sync", `${stats.bookings} bookings · ${stats.emails} customer emails · ${stats.complaints} complaints · ${stats.replies} replies · ${stats.overdue} overdue`, "info");
    return Response.json({ ok: true, ...stats });
  } catch (e) {
    const msg = String((e as Error).message || e);
    await sb.from("hq_integrations").upsert({ id: "outlook", name: "Outlook (bookings mailbox)", status: "needs_attention", last_sync: started, note: msg.slice(0, 300) });
    await log("Outlook sync failed", msg.slice(0, 300), "error");
    return Response.json({ ok: false, error: msg }, { status: 500 });
  }
});
