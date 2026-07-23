import { Link } from "react-router-dom";

export default function PageNotFound() {
  return (
    <div className="fixed inset-0 flex flex-col items-center justify-center gap-4 bg-background">
      <h1 className="font-display text-4xl font-bold">404</h1>
      <p className="text-muted-foreground">This page doesn't exist.</p>
      <Link to="/" className="text-paint-blue underline">Back to dashboard</Link>
    </div>
  );
}
