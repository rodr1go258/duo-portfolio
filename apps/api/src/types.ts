/** Minimal contract shared by pg.Pool and pg-mem pools. */
export interface QueryResultLike<T = Record<string, unknown>> {
  rows: T[];
  rowCount?: number;
}

export interface Queryable {
  query<T = Record<string, unknown>>(
    text: string,
    params?: unknown[]
  ): Promise<QueryResultLike<T>>;
}
