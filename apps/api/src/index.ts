import 'dotenv/config';
import { createApp } from './app';
import { createPool, waitForDatabase } from './db';
import { seedIfEmpty } from './seed';
import { Queryable } from './types';

async function resolvePool(): Promise<Queryable> {
  if (process.env.USE_MEMORY_DB === 'true') {
    const { createMemoryPool } = await import('./memory-db');
    return createMemoryPool();
  }
  const pool = createPool();
  await waitForDatabase(pool);
  return pool as unknown as Queryable;
}

async function bootstrap(): Promise<void> {
  const db = await resolvePool();
  const { app, repository } = createApp({ db });
  await repository.init();
  const seeded = await seedIfEmpty(repository);
  const port = Number(process.env.PORT ?? 3001);

  const server = app.listen(port, () => {
    console.log(`API lista en http://0.0.0.0:${port} (seed: ${seeded} proyectos)`);
  });

  const shutdown = (): void => {
    server.close(() => {
      console.log('API detenida');
      process.exit(0);
    });
  };
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

bootstrap().catch((error) => {
  console.error('No se pudo iniciar la API', error);
  process.exit(1);
});
