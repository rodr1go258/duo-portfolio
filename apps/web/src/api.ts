import { ContactPayload, Developer, Project } from './types';

const JSON_HEADERS = { 'Content-Type': 'application/json' };

async function parse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const body = (await response.json().catch(() => ({}))) as { error?: string };
    throw new Error(body.error ?? `Error HTTP ${response.status}`);
  }
  return response.json() as Promise<T>;
}

export const api = {
  health: () => fetch('/api/health').then((r) => parse<{ status: string }>(r)),
  developers: () => fetch('/api/developers').then((r) => parse<Developer[]>(r)),
  projects: () => fetch('/api/projects').then((r) => parse<Project[]>(r)),
  project: (id: string) => fetch(`/api/projects/${id}`).then((r) => parse<Project>(r)),
  contact: (payload: ContactPayload) =>
    fetch('/api/contact', {
      method: 'POST',
      headers: JSON_HEADERS,
      body: JSON.stringify(payload)
    }).then((r) => parse<{ ok: boolean; id: number }>(r))
};
