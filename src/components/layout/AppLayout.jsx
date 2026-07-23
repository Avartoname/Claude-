import { useState } from "react";
import { Outlet, Link, useLocation, Navigate } from "react-router-dom";
import { useAuth } from "@/lib/AuthContext";
import { filterNavGroups, canAccessPath } from "@/lib/roleAccess";
import {
  LayoutDashboard, CalendarCheck, Cake, Users, Package, UserCheck,
  School, Briefcase, Star, BookOpen, PoundSterling, BarChart3,
  LogOut, Menu, X, Calendar, Smartphone, Building2, Target, Crown, TrendingUp, CreditCard, Wand2, Gauge, ExternalLink, Receipt
} from "lucide-react";
import { base44 } from "@/api/base44Client";
import { Button } from "@/components/ui/button";

// Grouped nav sections
const NAV_GROUPS = [
  {
    label: "Operations",
    items: [
      { path: "/", icon: LayoutDashboard, label: "Dashboard" },
      { path: "/bookings", icon: CalendarCheck, label: "Bookings" },
      { path: "/pos", icon: Receipt, label: "POS" },
      { path: "https://paint-patch-flow.base44.app", icon: ExternalLink, label: "Book Online", external: true },
      { path: "/parties", icon: Cake, label: "Parties" },
      { path: "/party-charts", icon: TrendingUp, label: "Party Trends" },
      { path: "/events", icon: Calendar, label: "Events" },
      { path: "/leads", icon: Target, label: "Leads" },
    ],
  },
  {
    label: "People",
    items: [
      { path: "/customers", icon: Users, label: "Customers" },
      { path: "/schools", icon: School, label: "Schools" },
      { path: "/corporate", icon: Briefcase, label: "Corporate" },
      { path: "/staff", icon: UserCheck, label: "Staff" },
    ],
  },
  {
    label: "Business",
    items: [
      { path: "/inventory", icon: Package, label: "Inventory" },
      { path: "/finance", icon: PoundSterling, label: "Finance" },
      { path: "/stripe", icon: CreditCard, label: "Stripe" },
      { path: "/reviews", icon: Star, label: "Reviews" },
      { path: "/analytics", icon: BarChart3, label: "Analytics" },
    ],
  },
  {
    label: "Growth",
    items: [
      { path: "/social", icon: Smartphone, label: "Social" },
      { path: "/franchise", icon: Building2, label: "Franchise" },
      { path: "/executive", icon: Crown, label: "Executive" },
    ],
  },
  {
    label: "Knowledge",
    items: [
      { path: "/knowledge", icon: BookOpen, label: "Knowledge" },
    ],
  },
  {
    label: "Tools",
    items: [
      { path: "/app-builder", icon: Wand2, label: "App Builder" },
      { path: "/kpi", icon: Gauge, label: "KPI Machine" },
    ],
  },
];

export default function AppLayout() {
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);
  const { user } = useAuth();
  const userRole = user?.role;
  const visibleGroups = filterNavGroups(userRole, NAV_GROUPS);

  if (userRole && !canAccessPath(userRole, location.pathname)) {
    return <Navigate to="/bookings" replace />;
  }

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Top Nav */}
      <header className="border-b border-border/50 bg-card/90 backdrop-blur-xl sticky top-0 z-50">
        <div className="max-w-[1600px] mx-auto px-4 h-14 flex items-center justify-between gap-4">
          {/* Brand */}
          <Link to="/" className="flex items-center gap-2.5 shrink-0">
            <img
              src="https://media.base44.com/images/public/user_6a03b60bd7e5135024db5727/99e0481d8_BlackWhiteSimpleMonochromeInitialNameLogo660x660px.png"
              alt="Paint Patch HQ"
              className="h-8 w-8 rounded-full"
            />
            <span className="font-display text-lg font-bold bg-gradient-to-r from-paint-pink via-paint-orange to-paint-green bg-clip-text text-transparent hidden lg:block whitespace-nowrap">
              Paint Patch HQ
            </span>
          </Link>

          {/* Desktop Nav — grouped with separators */}
          <nav className="hidden md:flex items-center gap-0.5 overflow-x-auto flex-1 justify-center">
            {visibleGroups.map((group, gi) => (
              <div key={group.label} className="flex items-center">
                {gi > 0 && <div className="w-px h-5 bg-border/50 mx-1.5 shrink-0" />}
                {group.items.map((item) => {
                  const isActive = location.pathname === item.path;
                  const btn = (
                    <Button
                      variant={isActive ? "secondary" : "ghost"}
                      size="sm"
                      className={`gap-1.5 text-xs px-2.5 h-8 whitespace-nowrap ${isActive ? "bg-secondary text-foreground" : "text-muted-foreground hover:text-foreground"}`}
                    >
                      <item.icon className="h-3.5 w-3.5" />
                      <span>{item.label}</span>
                    </Button>
                  );
                  return item.external ? (
                    <a key={item.path} href={item.path} target="_blank" rel="noopener noreferrer">{btn}</a>
                  ) : (
                    <Link key={item.path} to={item.path}>{btn}</Link>
                  );
                })}
              </div>
            ))}
          </nav>

          <div className="flex items-center gap-2 shrink-0">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => base44.auth.logout()}
              className="text-muted-foreground hover:text-foreground h-8 w-8"
              title="Logout"
            >
              <LogOut className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="md:hidden h-8 w-8"
              onClick={() => setMobileOpen(!mobileOpen)}
            >
              {mobileOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
            </Button>
          </div>
        </div>

        {/* Mobile Nav */}
        {mobileOpen && (
          <div className="md:hidden border-t border-border/30 bg-card/95 backdrop-blur-xl">
            <div className="max-w-[1600px] mx-auto px-4 py-3">
              {visibleGroups.map((group) => (
                <div key={group.label} className="mb-3">
                  <p className="text-xs text-muted-foreground uppercase tracking-widest mb-1.5 px-1">{group.label}</p>
                  <div className="grid grid-cols-4 gap-1">
                    {group.items.map((item) => {
                      const isActive = location.pathname === item.path;
                      const btn = (
                        <Button
                          variant={isActive ? "secondary" : "ghost"}
                          size="sm"
                          className={`w-full gap-1 text-xs justify-start h-9 px-2 ${isActive ? "bg-secondary text-foreground" : "text-muted-foreground"}`}
                        >
                          <item.icon className="h-3.5 w-3.5 shrink-0" />
                          <span className="truncate">{item.label}</span>
                        </Button>
                      );
                      return item.external ? (
                        <a key={item.path} href={item.path} target="_blank" rel="noopener noreferrer" onClick={() => setMobileOpen(false)}>{btn}</a>
                      ) : (
                        <Link key={item.path} to={item.path} onClick={() => setMobileOpen(false)}>{btn}</Link>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </header>

      {/* Content */}
      <main className="flex-1 overflow-x-hidden">
        <Outlet />
      </main>
    </div>
  );
}
