import { z } from 'zod';
import {
  CreateProjectInput,
  Project,
  ProjectRepository
} from '../repositories/project.repository';

export class AppError extends Error {
  constructor(
    public readonly status: number,
    message: string
  ) {
    super(message);
    this.name = 'AppError';
  }
}

const currentYear = new Date().getFullYear();

export const createProjectSchema = z.object({
  title: z.string().trim().min(3, 'El título debe tener al menos 3 caracteres').max(80),
  description: z
    .string()
    .trim()
    .min(10, 'La descripción debe tener al menos 10 caracteres')
    .max(500),
  tech: z.array(z.string().trim().min(1)).min(1, 'Indica al menos una tecnología').max(10),
  owner: z.enum(['Ana', 'Luis'], {
    errorMap: () => ({ message: 'El responsable debe ser Ana o Luis' })
  }),
  year: z.number().int().min(2015).max(currentYear + 1, 'Año fuera de rango'),
  link: z.union([z.string().url('El enlace debe ser una URL válida'), z.literal('')]).optional()
});

export type CreateProjectDTO = z.infer<typeof createProjectSchema>;

export class ProjectService {
  constructor(private readonly repository: ProjectRepository) {}

  async list(): Promise<Project[]> {
    return this.repository.list();
  }

  async getById(id: number): Promise<Project> {
    const project = await this.repository.findById(id);
    if (!project) {
      throw new AppError(404, `No existe el proyecto con id ${id}`);
    }
    return project;
  }

  async create(dto: unknown): Promise<Project> {
    const parsed = createProjectSchema.safeParse(dto);
    if (!parsed.success) {
      const details = parsed.error.issues.map((issue) => issue.message).join('; ');
      throw new AppError(400, `Datos inválidos: ${details}`);
    }

    const existing = await this.repository.list();
    if (
      existing.some(
        (project) => project.title.trim().toLowerCase() === parsed.data.title.toLowerCase()
      )
    ) {
      throw new AppError(409, 'Ya existe un proyecto con ese título');
    }

    const input: CreateProjectInput = {
      title: parsed.data.title,
      description: parsed.data.description,
      tech: parsed.data.tech,
      owner: parsed.data.owner,
      year: parsed.data.year,
      link: parsed.data.link ? parsed.data.link : null
    };
    return this.repository.create(input);
  }

  async remove(id: number): Promise<void> {
    const deleted = await this.repository.remove(id);
    if (!deleted) {
      throw new AppError(404, `No existe el proyecto con id ${id}`);
    }
  }
}
