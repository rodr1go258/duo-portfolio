import { beforeEach, describe, expect, it, vi } from 'vitest';
import { ProjectRepository } from '../../src/repositories/project.repository';
import { AppError, ProjectService } from '../../src/services/project.service';

const sample = {
  id: 1,
  title: 'Pulse Board',
  description: 'Panel colaborativo en tiempo real para equipos remotos.',
  tech: ['React', 'Node.js'],
  owner: 'Ana',
  year: 2026,
  link: null
};

function createMockRepository() {
  return {
    init: vi.fn().mockResolvedValue(undefined),
    list: vi.fn().mockResolvedValue([]),
    findById: vi.fn().mockResolvedValue(null),
    create: vi.fn().mockImplementation(async (input) => ({ id: 99, ...input })),
    remove: vi.fn().mockResolvedValue(false)
  };
}

describe('ProjectService (unit tests)', () => {
  let repository: ReturnType<typeof createMockRepository>;
  let service: ProjectService;

  beforeEach(() => {
    repository = createMockRepository();
    service = new ProjectService(repository as unknown as ProjectRepository);
  });

  it('1. list() delega en el repositorio y devuelve los proyectos', async () => {
    repository.list.mockResolvedValue([sample]);
    await expect(service.list()).resolves.toEqual([sample]);
    expect(repository.list).toHaveBeenCalledOnce();
  });

  it('2. create() normaliza un payload válido y lo persiste', async () => {
    const result = await service.create({
      title: '  Nueva App  ',
      description: '  Una descripción suficientemente larga  ',
      tech: [' React '],
      owner: 'Luis',
      year: 2025,
      link: ''
    });
    expect(result).toMatchObject({
      title: 'Nueva App',
      description: 'Una descripción suficientemente larga',
      tech: ['React'],
      link: null
    });
    expect(repository.create).toHaveBeenCalledOnce();
  });

  it('3. create() rechaza títulos demasiado cortos con error 400', async () => {
    await expect(
      service.create({
        title: 'ab',
        description: 'Descripción suficientemente larga',
        tech: ['React'],
        owner: 'Ana',
        year: 2025
      })
    ).rejects.toMatchObject({ status: 400 });
    expect(repository.create).not.toHaveBeenCalled();
  });

  it('4. create() rechaza un año fuera de rango', async () => {
    await expect(
      service.create({
        title: 'Proyecto válido',
        description: 'Descripción suficientemente larga',
        tech: ['React'],
        owner: 'Ana',
        year: 1900
      })
    ).rejects.toBeInstanceOf(AppError);
  });

  it('5. create() rechaza un responsable que no sea del equipo', async () => {
    await expect(
      service.create({
        title: 'Proyecto válido',
        description: 'Descripción suficientemente larga',
        tech: ['React'],
        owner: 'Otro',
        year: 2025
      })
    ).rejects.toMatchObject({ status: 400 });
  });

  it('6. create() evita títulos duplicados (case-insensitive)', async () => {
    repository.list.mockResolvedValue([sample]);
    await expect(
      service.create({
        title: '  pulse board ',
        description: 'Descripción suficientemente larga',
        tech: ['React'],
        owner: 'Ana',
        year: 2025
      })
    ).rejects.toMatchObject({ status: 409, message: /Ya existe/ });
  });

  it('7. getById() lanza 404 cuando el proyecto no existe', async () => {
    await expect(service.getById(123)).rejects.toMatchObject({ status: 404 });
    expect(repository.findById).toHaveBeenCalledWith(123);
  });

  it('8. getById() devuelve el proyecto existente', async () => {
    repository.findById.mockResolvedValue(sample);
    await expect(service.getById(1)).resolves.toEqual(sample);
  });

  it('9. remove() lanza 404 si no se eliminó ninguna fila', async () => {
    await expect(service.remove(55)).rejects.toMatchObject({ status: 404 });
  });

  it('10. remove() termina correctamente al eliminar', async () => {
    repository.remove.mockResolvedValue(true);
    await expect(service.remove(1)).resolves.toBeUndefined();
  });
});
