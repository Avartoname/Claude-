import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '@/lib/AuthContext';
import UserNotRegisteredError from '@/components/UserNotRegisteredError';

const DefaultFallback = () => (
  <div className="fixed inset-0 flex items-center justify-center bg-background">
    <div className="w-8 h-8 border-4 border-muted border-t-primary rounded-full animate-spin"></div>
  </div>
);

export default function ProtectedRoute({ fallback = <DefaultFallback /> }) {
  const { isAuthenticated, isLoadingAuth, authError } = useAuth();
  const location = useLocation();

  if (isLoadingAuth) return fallback;

  if (authError?.type === 'user_not_registered') return <UserNotRegisteredError />;

  if (authError?.type === 'not_configured') {
    return (
      <div className="min-h-screen flex items-center justify-center p-6 text-center">
        <p className="text-sm text-muted-foreground max-w-md">
          HQ can't connect to its database. In Netlify, add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY, then redeploy.
        </p>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to={`/login?next=${encodeURIComponent(location.pathname)}`} replace />;
  }

  return <Outlet />;
}
