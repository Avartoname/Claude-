import { Link } from 'react-router-dom';

export const inputClass =
  'w-full rounded-xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-paint-pink focus:ring-2 focus:ring-paint-pink/30';
export const buttonClass =
  'w-full rounded-xl bg-paint-pink px-4 py-3 text-sm font-semibold text-white hover:bg-paint-pink/90 disabled:opacity-60';

export function Field({ id, label, ...props }) {
  return (
    <label htmlFor={id} className="block">
      <span className="mb-1.5 block text-xs font-medium uppercase tracking-widest text-muted-foreground">{label}</span>
      <input id={id} className={inputClass} {...props} />
    </label>
  );
}

export function Notice({ kind = 'info', children }) {
  if (!children) return null;
  const cls = kind === 'error' ? 'border-destructive/40 bg-destructive/10 text-destructive' : 'border-paint-green/40 bg-paint-green/10 text-paint-green';
  return <p role={kind === 'error' ? 'alert' : 'status'} className={`rounded-xl border px-4 py-3 text-sm ${cls}`}>{children}</p>;
}

export default function AuthShell({ title, subtitle, children, footer }) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4 py-12">
      <div className="w-full max-w-sm">
        <Link to="/" className="mb-8 block text-center">
          <span className="font-display text-3xl font-bold bg-gradient-to-r from-paint-pink via-paint-orange to-paint-green bg-clip-text text-transparent">
            Paint Patch HQ
          </span>
        </Link>
        <div className="rounded-2xl border border-border/50 bg-card p-6 shadow-xl">
          <h1 className="font-display text-xl font-bold">{title}</h1>
          {subtitle && <p className="mt-1 text-sm text-muted-foreground">{subtitle}</p>}
          <div className="mt-6 space-y-4">{children}</div>
        </div>
        {footer && <div className="mt-6 text-center text-sm text-muted-foreground">{footer}</div>}
      </div>
    </div>
  );
}
