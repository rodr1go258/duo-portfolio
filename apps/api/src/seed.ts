import { ProjectRepository } from './repositories/project.repository';

export const SEED_PROJECTS = [
  {
    title: 'Pulse Board',
    description:
      'Panel colaborativo en tiempo real para equipos remotos con métricas de ánimo y carga de trabajo.',
    tech: ['React', 'WebSocket', 'Node.js', 'PostgreSQL'],
    owner: 'Ana',
    year: 2026,
    link: 'https://example.com/pulse-board'
  },
  {
    title: 'Terraform Studio',
    description:
      'Generador visual de infraestructura como código con validación y coste estimado antes de aplicar.',
    tech: ['TypeScript', 'Terraform', 'AWS'],
    owner: 'Luis',
    year: 2025,
    link: 'https://example.com/terraform-studio'
  },
  {
    title: 'Recyclr',
    description:
      'Marketplace circular que conecta talleres locales con materiales recuperados y trazables.',
    tech: ['React', 'Fastify', 'PostgreSQL'],
    owner: 'Ana',
    year: 2024,
    link: 'https://example.com/recyclr'
  }
];

export async function seedIfEmpty(repository: ProjectRepository): Promise<number> {
  const current = await repository.list();
  if (current.length > 0) {
    return 0;
  }
  for (const project of SEED_PROJECTS) {
    await repository.create({ ...project, link: project.link ?? null });
  }
  return SEED_PROJECTS.length;
}
