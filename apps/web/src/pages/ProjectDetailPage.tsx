import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { api } from '../api';
import { Project } from '../types';

export function ProjectDetailPage() {
  const { id = '' } = useParams();
  const [project, setProject] = useState<Project | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    api
      .project(id)
      .then(setProject)
      .catch((err: Error) => setError(err.message));
  }, [id]);

  if (error) {
    return (
      <section data-testid="project-detail-error">
        <h1>No pudimos cargar el proyecto</h1>
        <p className="error">{error}</p>
        <Link className="button ghost" to="/proyectos">
          Volver a proyectos
        </Link>
      </section>
    );
  }

  if (!project) {
    return <p data-testid="project-detail-loading">Cargando detalle…</p>;
  }

  return (
    <article className="detail" data-testid="project-detail">
      <Link className="text-link" to="/proyectos">
        ← Volver al catálogo
      </Link>
      <p className="eyebrow">MVP · {project.year}</p>
      <h1 data-testid="detail-title">{project.title}</h1>
      <p className="lead">{project.description}</p>
      <div className="detail-meta" data-testid="detail-meta">
        <div>
          <span className="label">Responsable</span>
          <strong>{project.owner}</strong>
        </div>
        <div>
          <span className="label">Stack</span>
          <strong>{project.tech.join(' · ')}</strong>
        </div>
      </div>
      {project.link && (
        <a className="button primary" href={project.link} target="_blank" rel="noreferrer">
          Visitar proyecto ↗
        </a>
      )}
    </article>
  );
}
