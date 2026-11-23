import { newDb } from 'pg-mem';
import { Queryable } from './types';

/**
 * In-memory PostgreSQL-compatible pool used by E2E tests and local demos.
 * Kept in its own module so it is loaded lazily (pg-mem is a dev dependency).
 */
export function createMemoryPool(): Queryable {
  const db = newDb();
  const adapter = db.adapters.createPg();
  return new adapter.Pool() as unknown as Queryable;
}
