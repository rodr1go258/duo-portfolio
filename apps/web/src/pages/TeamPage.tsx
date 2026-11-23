import { useEffect, useState } from 'react';
import { api } from '../api';
import { Developer } from '../types';

export function TeamPage() {
  const [developers, setDevelopers] = useState<Developer[]>([]);
  const [error, setError] = useState('');

  useEffect(() => {
    api
      .developers()
      .then(setDevelopers)
      .catch((err: Error) => setError(err.message));
  }, []);

  return (
    <section data-testid="team-page">
      <p className="eyebrow">Quiénes somos</p>
      <h1 data-testid="team-title">Un dúo, dos especialidades</h1>
      {error && <p className="error">{error}</p>}
      <div className="card-grid" data-testid="team-grid">
        {developers.map((developer) => (
          <article className="card team-card" key={developer.id} data-testid="developer-card">
            <div className="avatar" data-testid="developer-avatar">
              {developer.avatar}
            </div>
            <h2>{developer.name}</h2>
            <p className="role">{developer.role}</p>
            <p>{developer.bio}</p>
            <ul className="tag-list">
              {developer.focus.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
            <a className="text-link" href={developer.github} target="_blank" rel="noreferrer">
              GitHub ↗
            </a>
          </article>
        ))}
      </div>
    </section>
  );
}
