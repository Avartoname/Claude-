import { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { supabase } from '@/api/supabaseClient';
import AuthShell, { Field, Notice, buttonClass } from '@/components/auth/AuthShell';

export default function Login() {
  const [params] = useSearchParams();
  const next = params.get('next') || '/';
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  const signIn = async (e) => {
    e.preventDefault();
    setBusy(true); setError(''); setInfo('');
    const { error: err } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    setBusy(false);
    if (err) return setError(err.message === 'Invalid login credentials' ? 'Email or password is incorrect.' : err.message);
    navigate(next.startsWith('/') ? next : '/', { replace: true });
  };

  const sendLink = async () => {
    if (!email.trim()) return setError('Enter your email first.');
    setBusy(true); setError(''); setInfo('');
    const { error: err } = await supabase.auth.signInWithOtp({
      email: email.trim(),
      options: { shouldCreateUser: false, emailRedirectTo: `${window.location.origin}${next.startsWith('/') ? next : '/'}` },
    });
    setBusy(false);
    if (err) return setError(err.message);
    setInfo(`Check ${email.trim()} for a sign-in link.`);
  };

  return (
    <AuthShell
      title="Sign in"
      subtitle="Use your work email."
      footer={<>New to HQ? <Link to="/register" className="text-paint-blue hover:underline">Request access</Link></>}
    >
      <form onSubmit={signIn} className="space-y-4">
        <Field id="email" label="Email" type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
        <Field id="password" label="Password" type="password" autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} />
        <Notice kind="error">{error}</Notice>
        <Notice>{info}</Notice>
        <button type="submit" className={buttonClass} disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}</button>
      </form>
      <div className="flex items-center justify-between text-sm">
        <button type="button" onClick={sendLink} disabled={busy} className="text-paint-blue hover:underline">Email me a sign-in link</button>
        <Link to="/forgot-password" className="text-muted-foreground hover:text-foreground">Forgot password?</Link>
      </div>
    </AuthShell>
  );
}
