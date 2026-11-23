import { Queryable } from '../types';

export interface Project {
  id: number;
  title: string;
  description: string;
  tech: string[];
  owner: string;
  year: number;
  link: string | null;
}

export interface CreateProjectInput {
  title: string;
  description: string;
  tech: string[];
  owner: string;
  year: number;
  link: string | null;
}

type ProjectRow = {
  id: number | string;
  title: string;
  description: string;
  tech: string;
  owner: string;
  year: number | string;
  link: string | null;
};

const toProject = (row: ProjectRow): Project => ({
  id: Number(row.id),
  title: row.title,
  description: row.description,
  tech: (() => {
    try {
      const parsed: unknown = JSON.parse(row.tech ?? '[]');
      return Array.isArray(parsed) ? parsed.map(String) : [];
    } catch {
      return [];
    }
  })(),
  owner: row.owner,
  year: Number(row.year),
  link: row.link ?? null
});

export class ProjectRepository {
  constructor(private readonly db: Queryable) {}

  async init(): Promise<void> {
    await this.db.query(`
      CREATE TABLE IF NOT EXISTS projects (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        tech TEXT NOT NULL DEFAULT '[]',
        owner TEXT NOT NULL,
        year INTEGER NOT NULL,
        link TEXT
      )
    `);
  }

  async list(): Promise<Project[]> {
    const result = await this.db.query<ProjectRow>(
      'SELECT * FROM projects ORDER BY year DESC, id DESC'
    );
    return result.rows.map(toProject);
  }

  async findById(id: number): Promise<Project | null> {
    const result = await this.db.query<ProjectRow>(
      'SELECT * FROM projects WHERE id = $1',
      [id]
    );
    return result.rows[0] ? toProject(result.rows[0]) : null;
  }

  async create(input: CreateProjectInput): Promise<Project> {
    const result = await this.db.query<ProjectRow>(
      `INSERT INTO projects (title, description, tech, owner, year, link)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        input.title,
        input.description,
        JSON.stringify(input.tech),
        input.owner,
        input.year,
        input.link
      ]
    );
    return toProject(result.rows[0]);
  }

  async remove(id: number): Promise<boolean> {
    const result = await this.db.query('DELETE FROM projects WHERE id = $1', [id]);
    return (result.rowCount ?? 0) > 0;
  }
}
