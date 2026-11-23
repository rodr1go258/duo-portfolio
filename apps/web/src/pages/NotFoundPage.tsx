import { Link } from 'react-router-dom';

export function NotFoundPage() {
  return (
    <section className="hero" data-testid="not-found-page">
      <p className="eyebrow">Error 404</p>
      <h1 data-testid="not-found-title">Esta página no existe</h1>
      <p className="lead">Quizá el enlace cambió o nunca estuvo aquí.</p>
      <Link className="button primary" to="/">
        Volver al inicio
      </Link>
    </section>
  );
}
