import { Toaster } from "@/components/ui/toaster"
import { QueryClientProvider } from '@tanstack/react-query'
import { queryClientInstance } from '@/lib/query-client'
import { BrowserRouter as Router, Route, Routes, Navigate } from 'react-router-dom';
import PageNotFound from './lib/PageNotFound';
import { AuthProvider, useAuth } from '@/lib/AuthContext';
import UserNotRegisteredError from '@/components/UserNotRegisteredError';
import ProtectedRoute from '@/components/ProtectedRoute';
import Login from '@/pages/Login';
import Register from '@/pages/Register';
import ForgotPassword from '@/pages/ForgotPassword';
import ResetPassword from '@/pages/ResetPassword';
import AppLayout from '@/components/layout/AppLayout';

// Pages
import HQDashboard from '@/pages/HQDashboard';
import Bookings from '@/pages/BookingAdmin';
import BookingWizard from '@/pages/BookingWizard';
import Parties from '@/pages/Parties';
import Events from '@/pages/Events';
import Leads from '@/pages/Leads';
import Customers from '@/pages/Customers';
import Inventory from '@/pages/Inventory';
import StaffHub from '@/pages/StaffHub';
import Schools from '@/pages/Schools';
import Corporate from '@/pages/Corporate';
import Finance from '@/pages/Finance';
import Reviews from '@/pages/Reviews';
import KnowledgeBase from '@/pages/KnowledgeBase';
import Analytics from '@/pages/Analytics';
import SocialHub from '@/pages/SocialHub';
import FranchiseHub from '@/pages/FranchiseHub';
import ExecutiveDashboard from '@/pages/ExecutiveDashboard';
import PartyCharts from '@/pages/PartyCharts';
import BookingConfirm from '@/pages/BookingConfirm';
import StripeDashboard from '@/pages/StripeDashboard';
import AppBuilder from '@/pages/AppBuilder';
import KPIMachine from '@/pages/KPIMachine';
import POS from '@/pages/POS';

const AuthenticatedApp = () => {
  const { isLoadingAuth, isLoadingPublicSettings, authError, navigateToLogin } = useAuth();

  if (isLoadingPublicSettings || isLoadingAuth) {
    return (
      <div className="fixed inset-0 flex items-center justify-center bg-background">
        <div className="w-8 h-8 border-4 border-muted border-t-primary rounded-full animate-spin"></div>
      </div>
    );
  }

  if (authError) {
    if (authError.type === 'user_not_registered') {
      return <UserNotRegisteredError />;
    } else if (authError.type === 'auth_required') {
      navigateToLogin();
      return null;
    }
  }

  return (
    <Routes>
      <Route path="/book" element={<BookingWizard />} />
      <Route path="/booking-confirm" element={<BookingConfirm />} />
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      <Route path="/forgot-password" element={<ForgotPassword />} />
      <Route path="/reset-password" element={<ResetPassword />} />
      <Route element={<AppLayout />}>
        <Route path="/" element={<HQDashboard />} />
        <Route path="/bookings" element={<Bookings />} />
        <Route path="/parties" element={<Parties />} />
        <Route path="/events" element={<Events />} />
        <Route path="/leads" element={<Leads />} />
        <Route path="/customers" element={<Customers />} />
        <Route path="/inventory" element={<Inventory />} />
        <Route path="/staff" element={<StaffHub />} />
        <Route path="/schools" element={<Schools />} />
        <Route path="/corporate" element={<Corporate />} />
        <Route path="/finance" element={<Finance />} />
        <Route path="/reviews" element={<Reviews />} />
        <Route path="/knowledge" element={<KnowledgeBase />} />
        <Route path="/analytics" element={<Analytics />} />
        <Route path="/social" element={<SocialHub />} />
        <Route path="/franchise" element={<FranchiseHub />} />
        <Route path="/executive" element={<ExecutiveDashboard />} />
        <Route path="/party-charts" element={<PartyCharts />} />
        <Route path="/stripe" element={<StripeDashboard />} />
        <Route path="/app-builder" element={<AppBuilder />} />
        <Route path="/kpi" element={<KPIMachine />} />
        <Route path="/pos" element={<POS />} />
      </Route>
      <Route path="*" element={<PageNotFound />} />
    </Routes>
  );
};

function App() {
  return (
    <AuthProvider>
      <QueryClientProvider client={queryClientInstance}>
        <Router>
          <AuthenticatedApp />
        </Router>
        <Toaster />
      </QueryClientProvider>
    </AuthProvider>
  )
}

export default App
