import { useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '@/api/supabaseClient';
import AuthShell, { Field, Notice, buttonClass } from '@/components/auth/AuthShell';

export default function ForgotPassword() {
  const [email, setEmail] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [sent, setSent] = useState(false);

  const submit = async (e) => {
    e.preventDefault();
    setBusy(true); setError('');
    const { error: err } = await supabase.auth.resetPasswordForEmail(email.trim(), {
      redirectTo: `${window.location.origin}/reset-password`,
    });
    setBusy(false);
    if (err) return setError(err.message);
    setSent(true);
  };

  return (
    <AuthShell title="Reset your password" footer={<Link to="/login" className="text-paint-blue hover:underline">Back to sign in</Link>}>
      {sent ? (
        <Notice>If {email.trim()} has an HQ account, a reset link is on its way.</Notice>
      ) : (
        <form onSubmit={submit} className="space-y-4">
          <Field id="email" label="Email" type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
          <Notice kind="error">{error}</Notice>
          <button type="submit" className={buttonClass} disabled={busy}>{busy ? 'Sending…' : 'Send reset link'}</button>
        </form>
      )}
    </AuthShell>
  );
}
