import cors from 'cors';
import express, { NextFunction, Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { DEVELOPERS } from './data/developers';
import { asQueryable, createPool } from './db';
import { contactRouter } from './routes/contact';
import { projectsRouter } from './routes/projects';
import { ProjectRepository } from './repositories/project.repository';
import { AppError, ProjectService } from './services/project.service';
import { Queryable } from './types';

export interface AppOptions {
  db?: Queryable;
}

export interface CreatedApp {
  app: express.Express;
  repository: ProjectRepository;
  service: ProjectService;
}

export function createApp(options: AppOptions = {}): CreatedApp {
  const db: Queryable = options.db ?? asQueryable(createPool());
  const repository = new ProjectRepository(db);
  const service = new ProjectService(repository);
  const app = express();

  app.disable('x-powered-by');
  app.use(cors());
  app.use(express.json({ limit: '100kb' }));

  app.get('/api/health', (_req, res) => {
    res.json({ status: 'ok', service: 'duo-portfolio-api', time: new Date().toISOString() });
  });

  app.get('/api/developers', (_req, res) => {
    res.json(DEVELOPERS);
  });

  app.use('/api/projects', projectsRouter(service));
  app.use('/api/contact', contactRouter());

  const webDist = path.resolve(__dirname, '..', '..', 'web', 'dist');
  if (fs.existsSync(path.join(webDist, 'index.html'))) {
    app.use(express.static(webDist));
    app.get('*', (_req, res) => res.sendFile(path.join(webDist, 'index.html')));
  }

  app.use((_req, res) => {
    res.status(404).json({ error: 'Recurso no encontrado' });
  });

  app.use((error: unknown, _req: Request, res: Response, _next: NextFunction) => {
    const status = error instanceof AppError ? error.status : 500;
    const message = error instanceof Error ? error.message : 'Error interno del servidor';
    if (status >= 500) {
      console.error(error);
    }
    res.status(status).json({ error: message });
  });

  return { app, repository, service };
}
