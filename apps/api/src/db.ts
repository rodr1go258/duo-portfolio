import { Pool } from 'pg';
import { Queryable } from './types';

export const DEFAULT_DATABASE_URL =
  'postgres://portfolio:portfolio@127.0.0.1:5432/portfolio';

export function createPool(connectionString?: string): Pool {
  return new Pool({
    connectionString: connectionString ?? process.env.DATABASE_URL ?? DEFAULT_DATABASE_URL,
    max: 10,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 5_000
  });
}

/** Retries the first connection so `docker compose up` works without race conditions. */
export async function waitForDatabase(
  pool: Pool,
  retries = 20,
  delayMs = 500
): Promise<void> {
  let lastError: unknown;
  for (let attempt = 1; attempt <= retries; attempt += 1) {
    try {
      await pool.query('SELECT 1');
      return;
    } catch (error) {
      lastError = error;
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }
  throw new Error(
    `No se pudo conectar a PostgreSQL tras ${retries} intentos: ${String(lastError)}`
  );
}

export function asQueryable(pool: Pool): Queryable {
  return pool as unknown as Queryable;
}
