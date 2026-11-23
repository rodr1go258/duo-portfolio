import { describe, expect, it } from 'vitest';
import { DEVELOPERS } from '../../src/data/developers';
import { SEED_PROJECTS } from '../../src/seed';

describe('Dominio del MVP (unit tests)', () => {
  it('1. el equipo está formado exactamente por 2 personas', () => {
    expect(DEVELOPERS).toHaveLength(2);
    expect(DEVELOPERS.map((d) => d.name)).toEqual(['Ana Torres', 'Luis Ramírez']);
  });

  it('2. cada desarrollador tiene roles y tecnologías definidas', () => {
    for (const developer of DEVELOPERS) {
      expect(developer.role.length).toBeGreaterThan(3);
      expect(developer.focus.length).toBeGreaterThan(0);
      expect(developer.avatar).toMatch(/^[A-Z]{2}$/);
    }
  });

  it('3. el catálogo semilla tiene al menos 3 proyectos novedosos', () => {
    expect(SEED_PROJECTS.length).toBeGreaterThanOrEqual(3);
  });

  it('4. todos los proyectos semilla tienen un responsable del equipo', () => {
    const owners = DEVELOPERS.map((d) => d.name.split(' ')[0]);
    for (const project of SEED_PROJECTS) {
      expect(owners).toContain(project.owner);
    }
  });

  it('5. todos los proyectos semilla declaran tecnologías', () => {
    for (const project of SEED_PROJECTS) {
      expect(project.tech.length).toBeGreaterThanOrEqual(2);
    }
  });

  it('6. los años semilla son coherentes', () => {
    for (const project of SEED_PROJECTS) {
      expect(project.year).toBeGreaterThanOrEqual(2020);
      expect(project.year).toBeLessThanOrEqual(new Date().getFullYear() + 1);
    }
  });
});
