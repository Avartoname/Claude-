import { useMemo, useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { base44 } from "@/api/base44Client";
import { motion } from "framer-motion";
import { Link } from "react-router-dom";
import {
  CalendarCheck, PoundSterling, Users, Cake, Star, CheckSquare,
  MapPin, Zap, TrendingUp, AlertTriangle, ChevronRight, CreditCard, ShoppingBag, CalendarDays
} from "lucide-react";

const TODAY = new Date().toISOString().split("T")[0];

const isSameDay = (taskDate, targetDate) => taskDate?.slice(0, 10) === targetDate;

const EVENTS_UPCOMING = [
  { name: "Slime Lab", date: "2026-06-14", icon: "🧪", color: "from-paint-green/20 to-transparent", badge: "bg-paint-green" },
  { name: "Paws & Paint", date: "2026-07-05", icon: "🐾", color: "from-paint-blue/20 to-transparent", badge: "bg-paint-blue" },
  { name: "Home Education Sessions", date: "2026-06-10", icon: "📚", color: "from-paint-purple/20 to-transparent", badge: "bg-paint-purple" },
];

function KpiCard({ label, value, icon: IconComp, color, delay = 0 }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay }}
      className="bg-card border border-border/50 rounded-2xl p-5 relative overflow-hidden"
    >
      <div className="absolute inset-0 bg-gradient-to-br from-white/[0.02] to-transparent pointer-events-none" />
      <p className="text-xs text-muted-foreground uppercase tracking-widest mb-2">{label}</p>
      <p className={`font-display text-3xl font-bold ${color}`}>{value}</p>
      <div className="absolute top-4 right-4 w-9 h-9 rounded-xl flex items-center justify-center bg-white/5">
        <IconComp className={`h-5 w-5 ${color}`} />
      </div>
    </motion.div>
  );
}

export default function HQDashboard() {

  const { data: stripeData } = useQuery({
    queryKey: ["stripeData"],
    queryFn: () => base44.functions.invoke("getStripeData", {}).then(r => r.data),
    refetchInterval: 300000, // every 5 min
  });

  const { data: bookings = [], isError: bookingsError } = useQuery({
    queryKey: ["bookings"],
    queryFn: () => base44.entities.Booking.list("-date", 200),
    refetchInterval: 60000,
  });
  const { data: parties = [] } = useQuery({
    queryKey: ["parties"],
    queryFn: () => base44.entities.Party.list("-date", 100),
  });
  const { data: inventory = [] } = useQuery({
    queryKey: ["inventory"],
    queryFn: () => base44.entities.InventoryItem.list(),
  });
  const { data: reviews = [] } = useQuery({
    queryKey: ["reviews"],
    queryFn: () => base44.entities.Review.list("-date", 20),
  });
  const { data: staff = [] } = useQuery({
    queryKey: ["staff"],
    queryFn: () => base44.entities.StaffMember.list(),
  });
  const { data: posSales = [] } = useQuery({
    queryKey: ["posSales"],
    queryFn: () => base44.entities.PosSale.list("-created_date", 200),
    refetchInterval: 60000,
  });

  const todayBookings = useMemo(() => bookings.filter((b) => isSameDay(b.date, TODAY)), [bookings]);
  const todayParties = useMemo(() => parties.filter((p) => p.date === TODAY), [parties]);
  const todayRevenue = useMemo(() => todayBookings.reduce((s, b) => s + (Number(b.revenue) || 0), 0), [todayBookings]);
  const todayGuests = useMemo(() => todayBookings.reduce((s, b) => s + (Number(b.guests) || 0), 0), [todayBookings]);

  const mkRevenue = useMemo(() => todayBookings.filter((b) => b.location === "Milton Keynes").reduce((s, b) => s + (Number(b.revenue) || 0), 0), [todayBookings]);
  const mkGuests = useMemo(() => todayBookings.filter((b) => b.location === "Milton Keynes").reduce((s, b) => s + (Number(b.guests) || 0), 0), [todayBookings]);
  const hatRevenue = useMemo(() => todayBookings.filter((b) => b.location === "Hatfield").reduce((s, b) => s + (Number(b.revenue) || 0), 0), [todayBookings]);
  const hatGuests = useMemo(() => todayBookings.filter((b) => b.location === "Hatfield").reduce((s, b) => s + (Number(b.guests) || 0), 0), [todayBookings]);

  const lowStock = useMemo(() => inventory.filter((i) => Number(i.current_stock) <= Number(i.low_stock_threshold)), [inventory]);
  const avgRating = useMemo(() => reviews.length ? (reviews.reduce((s, r) => s + (Number(r.rating) || 0), 0) / reviews.length).toFixed(1) : "—", [reviews]);
  const activeStaff = useMemo(() => staff.filter((s) => s.status === "active").length, [staff]);

  const todayPosSales = useMemo(
    () => posSales.filter((s) => s.created_date?.slice(0, 10) === TODAY),
    [posSales]
  );
  const todaySalesTotal = useMemo(
    () => todayPosSales.reduce((s, p) => s + (Number(p.total) || 0), 0),
    [todayPosSales]
  );

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 py-8">
      {/* Header */}
      <motion.div initial={{ opacity: 0, y: -12 }} animate={{ opacity: 1, y: 0 }} className="mb-8">
        <div className="flex items-center gap-3 mb-1">
          <span className="text-3xl">🎨</span>
          <h1 className="font-display text-4xl font-bold bg-gradient-to-r from-paint-pink via-paint-orange to-paint-green bg-clip-text text-transparent">
            Paint Patch HQ
          </h1>
        </div>
        <p className="text-muted-foreground text-sm ml-12 font-body italic">
          "Creating unforgettable memories, one splash at a time."
        </p>
      </motion.div>

      {/* TODAY KPIs */}
      <p className="text-xs font-medium text-muted-foreground uppercase tracking-widest mb-3">Today's Overview</p>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <KpiCard label="Bookings Today" value={todayBookings.length} icon={CalendarCheck} color="text-paint-blue" delay={0} />
        <KpiCard label="Revenue Today" value={`£${todayRevenue.toLocaleString()}`} icon={PoundSterling} color="text-paint-green" delay={0.05} />
        <KpiCard label="Guests Today" value={todayGuests} icon={Users} color="text-paint-orange" delay={0.1} />
        <KpiCard label="Parties Today" value={todayParties.length} icon={Cake} color="text-paint-pink" delay={0.15} />
      </div>

      {/* LOCATIONS + UPCOMING + ALERTS */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">

        {/* Locations */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }}
          className="bg-card border border-border/50 rounded-2xl p-6 col-span-1">
          <div className="flex items-center gap-2 mb-5">
            <MapPin className="h-4 w-4 text-paint-blue" />
            <h2 className="font-display font-semibold text-sm uppercase tracking-widest text-muted-foreground">Locations</h2>
          </div>
          {[
            { name: "Milton Keynes", revenue: mkRevenue, guests: mkGuests, color: "border-paint-pink/40 bg-paint-pink/5" },
            { name: "Hatfield", revenue: hatRevenue, guests: hatGuests, color: "border-paint-blue/40 bg-paint-blue/5" },
          ].map((loc) => (
            <div key={loc.name} className={`border ${loc.color} rounded-xl p-4 mb-3`}>
              <p className="font-display font-semibold mb-3">{loc.name}</p>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <p className="text-xs text-muted-foreground">Revenue</p>
                  <p className="font-bold text-paint-green font-display">£{loc.revenue.toLocaleString()}</p>
                </div>
                <div>
                  <p className="text-xs text-muted-foreground">Guests</p>
                  <p className="font-bold text-paint-orange font-display">{loc.guests}</p>
                </div>
              </div>
            </div>
          ))}
        </motion.div>

        {/* Upcoming Events */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.25 }}
          className="bg-card border border-border/50 rounded-2xl p-6 col-span-1">
          <div className="flex items-center gap-2 mb-5">
            <Zap className="h-4 w-4 text-paint-orange" />
            <h2 className="font-display font-semibold text-sm uppercase tracking-widest text-muted-foreground">Upcoming Events</h2>
          </div>
          <div className="space-y-2">
            {EVENTS_UPCOMING.map((ev) => (
              <div key={ev.name} className={`bg-gradient-to-r ${ev.color} rounded-xl px-3 py-2.5 flex items-center gap-3`}>
                <span className="text-xl">{ev.icon}</span>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium truncate">{ev.name}</p>
                  <p className="text-xs text-muted-foreground">{new Date(ev.date).toLocaleDateString("en-GB", { day: "numeric", month: "short" })}</p>
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Team & Alerts */}
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }}
          className="bg-card border border-border/50 rounded-2xl p-6 col-span-1 flex flex-col gap-4">
          <div>
            <div className="flex items-center gap-2 mb-4">
              <Star className="h-4 w-4 text-paint-green" />
              <h2 className="font-display font-semibold text-sm uppercase tracking-widest text-muted-foreground">Team Performance</h2>
            </div>
            <div className="grid grid-cols-3 gap-3">
              {[
                { label: "Staff Active", value: activeStaff, color: "text-paint-green" },
                { label: "Avg Rating", value: avgRating, color: "text-paint-orange" },
                { label: "Reviews", value: reviews.length, color: "text-paint-blue" },
              ].map((s) => (
                <div key={s.label} className="bg-secondary/40 rounded-xl p-3 text-center">
                  <p className={`font-display text-xl font-bold ${s.color}`}>{s.value}</p>
                  <p className="text-xs text-muted-foreground leading-tight mt-1">{s.label}</p>
                </div>
              ))}
            </div>
          </div>

          <div>
            <div className="flex items-center gap-2 mb-3">
              <AlertTriangle className="h-4 w-4 text-destructive" />
              <h2 className="font-display font-semibold text-sm uppercase tracking-widest text-muted-foreground">Stock Alerts</h2>
            </div>
            {lowStock.length === 0 ? (
              <p className="text-xs text-paint-green font-medium">✓ All stock levels OK</p>
            ) : (
              <div className="space-y-1.5">
                {lowStock.slice(0, 4).map((item) => (
                  <div key={item.id} className="flex items-center justify-between text-xs">
                    <span className="text-muted-foreground truncate">{item.name}</span>
                    <span className="text-destructive font-bold ml-2">{item.current_stock} left</span>
                  </div>
                ))}
              </div>
            )}
          </div>

          <Link to="/bookings" className="mt-auto flex items-center gap-2 text-xs text-paint-blue hover:text-paint-blue/80 transition-colors font-medium">
            View all bookings <ChevronRight className="h-3 w-3" />
          </Link>
        </motion.div>
      </div>

      {/* Daily Performance Report */}
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.18 }}
        className="bg-card border border-border/50 rounded-2xl p-6 mb-6">
        <div className="flex items-center gap-2 mb-5">
          <TrendingUp className="h-4 w-4 text-paint-green" />
          <h2 className="font-display font-semibold text-sm uppercase tracking-widest text-muted-foreground">Daily Performance Report</h2>
          <span className="ml-auto text-xs text-muted-foreground">{new Date().toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long" })}</span>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-paint-green/5 border border-paint-green/20 rounded-xl p-5 relative overflow-hidden">
            <ShoppingBag className="absolute top-4 right-4 h-5 w-5 text-paint-green/50" />
            <p className="text-xs text-muted-foreground uppercase tracking-widest mb-2">Daily Sales (POS)</p>
            <p className="font-display text-3xl font-bold text-paint-green">£{todaySalesTotal.toLocaleString("en-GB", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
            <p className="text-xs text-muted-foreground mt-1">{todayPosSales.length} transactions</p>
          </div>
          <div className="bg-paint-blue/5 border border-paint-blue/20 rounded-xl p-5 relative overflow-hidden">
            <CalendarDays className="absolute top-4 right-4 h-5 w-5 text-paint-blue/50" />
            <p className="text-xs text-muted-foreground uppercase tracking-widest mb-2">Total Bookings Today</p>
            <p className="font-display text-3xl font-bold text-paint-blue">{todayBookings.length}</p>
            <p className="text-xs text-muted-foreground mt-1">{todayGuests} total guests</p>
          </div>
          <div className="bg-paint-pink/5 border border-paint-pink/20 rounded-xl p-5 relative overflow-hidden">
            <PoundSterling className="absolute top-4 right-4 h-5 w-5 text-paint-pink/50" />
            <p className="text-xs text-muted-foreground uppercase tracking-widest mb-2">Booking Revenue</p>
            <p className="font-display text-3xl font-bold text-paint-pink">£{todayRevenue.toLocaleString("en-GB", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
            <p className="text-xs text-muted-foreground mt-1">from sessions today</p>
          </div>
          <div className="bg-paint-orange/5 border border-paint-orange/20 rounded-xl p-5 relative overflow-hidden">
            <Users className="absolute top-4 right-4 h-5 w-5 text-paint-orange/50" />
            <p className="text-xs text-muted-foreground uppercase tracking-widest mb-2">Combined Total</p>
            <p className="font-display text-3xl font-bold text-paint-orange">£{(todaySalesTotal + todayRevenue).toLocaleString("en-GB", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
            <p className="text-xs text-muted-foreground mt-1">sales + bookings</p>
          </div>
        </div>
      </motion.div>

      {/* Stripe Data */}
      {true && (
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.32 }}
          className="bg-card border border-border/50 rounded-2xl p-6 mb-6">
          <div className="flex items-center gap-2 mb-5">
            <CreditCard className="h-4 w-4 text-paint-purple" />
            <h2 className="font-display font-semibold text-sm uppercase tracking-widest text-muted-foreground">Stripe Payments</h2>
            <span className="ml-auto text-xs text-muted-foreground">Last 30 days</span>
          </div>
          {!stripeData ? (
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {Array(4).fill(0).map((_, i) => <div key={i} className="h-16 bg-secondary/40 rounded-xl animate-pulse" />)}
            </div>
          ) : stripeData.error ? (
            <p className="text-sm text-destructive">{stripeData.error}</p>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Stats */}
              <div className="grid grid-cols-2 md:grid-cols-2 gap-3 md:col-span-2">
                {[
                  { label: "Revenue (30d)", value: `£${(stripeData.total_30_days / 100).toLocaleString("en", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`, color: "text-paint-green" },
                  { label: "Payments (30d)", value: stripeData.count_30_days, color: "text-paint-blue" },
                  { label: "Available Balance", value: `£${(stripeData.available / 100).toLocaleString("en", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`, color: "text-paint-green" },
                  { label: "Pending Payout", value: `£${(stripeData.pending / 100).toLocaleString("en", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`, color: "text-paint-orange" },
                ].map((s) => (
                  <div key={s.label} className="bg-secondary/40 rounded-xl p-4">
                    <p className="text-xs text-muted-foreground mb-1">{s.label}</p>
                    <p className={`font-display text-xl font-bold ${s.color}`}>{s.value}</p>
                  </div>
                ))}
              </div>
              {/* Recent payments */}
              <div className="space-y-2">
                <p className="text-xs text-muted-foreground font-medium uppercase tracking-widest mb-3">Recent Payments</p>
                {stripeData.recent_payments?.length === 0 && <p className="text-xs text-muted-foreground">No payments yet</p>}
                {stripeData.recent_payments?.map((p) => (
                  <div key={p.id} className="flex items-center gap-2 py-1.5 border-b border-border/20 last:border-0">
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-medium truncate">{p.customer_email || p.metadata?.booking_id || p.id.slice(-8)}</p>
                      <p className="text-xs text-muted-foreground">{new Date(p.created * 1000).toLocaleDateString("en-GB", { day: "numeric", month: "short" })}</p>
                    </div>
                    <p className="text-sm font-bold text-paint-green shrink-0">£{(p.amount / 100).toFixed(2)}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </motion.div>
      )}

      {/* Recent Bookings */}
      <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.35 }}
        className="bg-card border border-border/50 rounded-2xl p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <TrendingUp className="h-4 w-4 text-paint-pink" />
            <h2 className="font-display font-semibold text-sm uppercase tracking-widest text-muted-foreground">Recent Bookings</h2>
          </div>
          <Link to="/bookings" className="flex items-center gap-1.5 text-xs font-medium bg-paint-blue/10 hover:bg-paint-blue/20 text-paint-blue px-3 py-1.5 rounded-lg transition-colors">
            <CalendarCheck className="h-3.5 w-3.5" /> Booking Dashboard
          </Link>
        </div>
        {bookingsError ? (
          <p className="text-destructive text-sm text-center py-6">Failed to load bookings.</p>
        ) : bookings.length === 0 ? (
          <p className="text-muted-foreground text-sm text-center py-6">No bookings yet. Add your first booking!</p>
        ) : (
          <div className="space-y-2">
            {bookings.slice(0, 6).map((b) => (
              <div key={b.id} className="flex items-center gap-3 py-2 border-b border-border/30 last:border-0">
                <div className="w-8 h-8 rounded-full bg-paint-pink/20 flex items-center justify-center text-xs font-bold text-paint-pink">
                  {(b.customer_name || "?")[0].toUpperCase()}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium truncate">{b.customer_name}</p>
                  <p className="text-xs text-muted-foreground">{b.session_type} · {b.location} · {b.date}</p>
                </div>
                <div className="text-right shrink-0">
                  <p className="text-sm font-bold text-paint-green">£{Number(b.revenue || 0).toLocaleString()}</p>
                  <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                    b.status === "confirmed" ? "bg-paint-green/20 text-paint-green" :
                    b.status === "completed" ? "bg-paint-blue/20 text-paint-blue" :
                    b.status === "cancelled" ? "bg-destructive/20 text-destructive" :
                    b.status === "checked_in" ? "bg-paint-orange/20 text-paint-orange" :
                    "bg-secondary text-muted-foreground"
                  }`}>{b.status}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </motion.div>
    </div>
  );
}
