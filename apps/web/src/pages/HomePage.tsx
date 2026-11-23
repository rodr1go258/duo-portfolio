import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';

export function HomePage() {
  const [projectCount, setProjectCount] = useState<number | null>(null);

  useEffect(() => {
    api
      .projects()
      .then((projects) => setProjectCount(projects.length))
      .catch(() => setProjectCount(null));
  }, []);

  return (
    <section className="hero" data-testid="home-page">
      <p className="eyebrow">MVP · Dos personas · Un objetivo</p>
      <h1 data-testid="home-title">Dos mentes. Un producto.</h1>
      <p className="lead">
        Somos Ana y Luis. Diseñamos y construimos productos digitales pequeños, útiles y
        listos para producción. Este portafolio es nuestro laboratorio abierto.
      </p>
      <div className="stats" data-testid="home-stats">
        <div className="stat">
          <strong data-testid="stat-team">2</strong>
          <span>personas en el equipo</span>
        </div>
        <div className="stat">
          <strong data-testid="stat-projects">{projectCount ?? '—'}</strong>
          <span>MVPs publicados</span>
        </div>
        <div className="stat">
          <strong>3</strong>
          <span>capas: web, API y datos</span>
        </div>
      </div>
      <div className="cta-row">
        <Link className="button primary" to="/proyectos" data-testid="cta-projects">
          Ver proyectos
        </Link>
        <Link className="button ghost" to="/contacto">
          Hablemos
        </Link>
      </div>
    </section>
  );
}
