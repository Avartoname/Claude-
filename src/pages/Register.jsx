import { useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '@/api/supabaseClient';
import AuthShell, { Field, Notice, buttonClass } from '@/components/auth/AuthShell';

export default function Register() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [done, setDone] = useState(false);

  const submit = async (e) => {
    e.preventDefault();
    if (password.length < 8) return setError('Use at least 8 characters for your password.');
    setBusy(true); setError('');
    const { error: err } = await supabase.auth.signUp({
      email: email.trim(),
      password,
      options: { data: { full_name: name.trim() }, emailRedirectTo: `${window.location.origin}/` },
    });
    setBusy(false);
    if (err) return setError(err.message);
    setDone(true);
  };

  if (done) {
    return (
      <AuthShell title="Request sent" footer={<Link to="/login" className="text-paint-blue hover:underline">Back to sign in</Link>}>
        <p className="text-sm text-muted-foreground">
          Confirm your email using the link we've sent to <b className="text-foreground">{email.trim()}</b>.
          An HQ manager then needs to approve your access before you can sign in.
        </p>
      </AuthShell>
    );
  }

  return (
    <AuthShell
      title="Request access"
      subtitle="For Paint Patch staff. A manager approves new accounts."
      footer={<>Already have access? <Link to="/login" className="text-paint-blue hover:underline">Sign in</Link></>}
    >
      <form onSubmit={submit} className="space-y-4">
        <Field id="name" label="Full name" autoComplete="name" required value={name} onChange={(e) => setName(e.target.value)} />
        <Field id="email" label="Work email" type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
        <Field id="password" label="Password (8+ characters)" type="password" autoComplete="new-password" required value={password} onChange={(e) => setPassword(e.target.value)} />
        <Notice kind="error">{error}</Notice>
        <button type="submit" className={buttonClass} disabled={busy}>{busy ? 'Sending…' : 'Request access'}</button>
      </form>
    </AuthShell>
  );
}
