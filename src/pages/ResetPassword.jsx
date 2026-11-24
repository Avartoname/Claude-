import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '@/api/supabaseClient';
import AuthShell, { Field, Notice, buttonClass } from '@/components/auth/AuthShell';

export default function ResetPassword() {
  const navigate = useNavigate();
  const [ready, setReady] = useState(false);
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  // The reset link signs the user in with a recovery session
  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setReady(Boolean(data.session)));
    const { data: sub } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'PASSWORD_RECOVERY' || session) setReady(true);
    });
    return () => sub?.subscription?.unsubscribe();
  }, []);

  const submit = async (e) => {
    e.preventDefault();
    if (password.length < 8) return setError('Use at least 8 characters.');
    setBusy(true); setError('');
    const { error: err } = await supabase.auth.updateUser({ password });
    setBusy(false);
    if (err) return setError(err.message);
    navigate('/', { replace: true });
  };

  return (
    <AuthShell title="Choose a new password" footer={<Link to="/login" className="text-paint-blue hover:underline">Back to sign in</Link>}>
      {!ready ? (
        <Notice kind="error">This reset link has expired or was already used. Request a new one from "Forgot password?".</Notice>
      ) : (
        <form onSubmit={submit} className="space-y-4">
          <Field id="password" label="New password (8+ characters)" type="password" autoComplete="new-password" required value={password} onChange={(e) => setPassword(e.target.value)} />
          <Notice kind="error">{error}</Notice>
          <button type="submit" className={buttonClass} disabled={busy}>{busy ? 'Saving…' : 'Save password'}</button>
        </form>
      )}
    </AuthShell>
  );
}
