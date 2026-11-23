import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';
import { createApp } from '../../src/app';
import { createMemoryPool } from '../../src/memory-db';

type AppInstance = ReturnType<typeof createApp>['app'];

let app: AppInstance;
const validProject = {
  title: 'Integración Continua',
  description: 'Proyecto creado desde la suite de integración.',
  tech: ['Vitest', 'Supertest'],
  owner: 'Luis',
  year: 2026,
  link: 'https://example.com/ci'
};

describe('API REST (integration tests con PostgreSQL en memoria)', () => {
  beforeAll(async () => {
    const db = createMemoryPool();
    const created = createApp({ db });
    await created.repository.init();
    app = created.app;
  });

  it('1. GET /api/health responde 200 con status ok', async () => {
    const response = await request(app).get('/api/health').expect(200);
    expect(response.body.status).toBe('ok');
    expect(response.body.service).toBe('duo-portfolio-api');
  });

  it('2. GET /api/developers devuelve los 2 integrantes', async () => {
    const response = await request(app).get('/api/developers').expect(200);
    expect(response.body).toHaveLength(2);
    expect(response.body[0].name).toBe('Ana Torres');
  });

  it('3. GET /api/projects devuelve una lista vacía inicialmente', async () => {
    const response = await request(app).get('/api/projects').expect(200);
    expect(response.body).toEqual([]);
  });

  it('4. POST /api/projects crea un proyecto y responde 201', async () => {
    const response = await request(app).post('/api/projects').send(validProject).expect(201);
    expect(response.body).toMatchObject({
      title: validProject.title,
      owner: 'Luis',
      tech: ['Vitest', 'Supertest']
    });
    expect(response.body.id).toBeGreaterThan(0);
  });

  it('5. POST /api/projects con datos inválidos responde 400', async () => {
    const response = await request(app)
      .post('/api/projects')
      .send({ ...validProject, title: 'x', year: 1800 })
      .expect(400);
    expect(response.body.error).toMatch(/Datos inválidos/);
  });

  it('6. GET /api/projects lista el proyecto creado', async () => {
    const response = await request(app).get('/api/projects').expect(200);
    expect(response.body).toHaveLength(1);
    expect(response.body[0].title).toBe(validProject.title);
  });

  it('7. GET /api/projects/:id devuelve el detalle', async () => {
    const list = await request(app).get('/api/projects').expect(200);
    const id = list.body[0].id;
    const response = await request(app).get(`/api/projects/${id}`).expect(200);
    expect(response.body.description).toBe(validProject.description);
  });

  it('8. GET /api/projects/9999 responde 404', async () => {
    const response = await request(app).get('/api/projects/9999').expect(404);
    expect(response.body.error).toMatch(/No existe/);
  });

  it('9. POST duplicado responde 409', async () => {
    await request(app)
      .post('/api/projects')
      .send({ ...validProject, title: validProject.title.toUpperCase() })
      .expect(409);
  });

  it('10. DELETE /api/projects/:id elimina y luego responde 404', async () => {
    const list = await request(app).get('/api/projects').expect(200);
    const id = list.body[0].id;
    await request(app).delete(`/api/projects/${id}`).expect(204);
    await request(app).get(`/api/projects/${id}`).expect(404);
  });

  it('11. POST /api/contact acepta un mensaje válido (202)', async () => {
    const response = await request(app)
      .post('/api/contact')
      .send({ name: 'Marta', email: 'marta@example.com', message: 'Hola equipo, buen trabajo.' })
      .expect(202);
    expect(response.body.ok).toBe(true);
    expect(response.body.id).toBe(1);
  });

  it('12. POST /api/contact rechaza un email inválido (400)', async () => {
    const response = await request(app)
      .post('/api/contact')
      .send({ name: 'Marta', email: 'no-es-email', message: 'Hola equipo, buen trabajo.' })
      .expect(400);
    expect(response.body.error).toMatch(/correo válido/);
  });
});
