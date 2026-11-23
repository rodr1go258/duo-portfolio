import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import { Project } from '../types';

export function ProjectsPage() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    api
      .projects()
      .then(setProjects)
      .catch((err: Error) => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  return (
    <section data-testid="projects-page">
      <p className="eyebrow">Catálogo</p>
      <h1 data-testid="projects-title">Proyectos que hemos llevado a producción</h1>

      {loading && <p data-testid="projects-loading">Cargando proyectos…</p>}
      {error && <p className="error" data-testid="projects-error">{error}</p>}

      <div className="card-grid" data-testid="projects-grid">
        {projects.map((project) => (
          <article className="card" key={project.id} data-testid="project-card">
            <div className="card-head">
              <span className="pill">{project.year}</span>
              <span className="owner">Responsable: {project.owner}</span>
            </div>
            <h2>{project.title}</h2>
            <p>{project.description}</p>
            <ul className="tag-list">
              {project.tech.map((tech) => (
                <li key={tech}>{tech}</li>
              ))}
            </ul>
            <Link className="text-link" to={`/proyectos/${project.id}`}>
              Ver detalle →
            </Link>
          </article>
        ))}
      </div>

      {!loading && !error && projects.length === 0 && (
        <p data-testid="projects-empty">Todavía no hay proyectos publicados.</p>
      )}
    </section>
  );
}
