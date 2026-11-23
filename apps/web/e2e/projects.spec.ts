import { expect, test } from '@playwright/test';

test.describe('Proyectos, equipo, contacto y API', () => {
  test('5. el catálogo lista los 3 MVPs semilla', async ({ page }) => {
    await page.goto('/proyectos');
    await expect(page.getByTestId('project-card')).toHaveCount(3);
    await expect(page.getByTestId('projects-grid')).toContainText('Pulse Board');
    await expect(page.getByTestId('projects-grid')).toContainText('Terraform Studio');
  });

  test('6. se puede abrir el detalle de un proyecto', async ({ page }) => {
    await page.goto('/proyectos');
    await page.getByTestId('project-card').first().getByRole('link').click();
    await expect(page).toHaveURL(/\/proyectos\/\d+$/);
    await expect(page.getByTestId('detail-title')).toHaveText('Pulse Board');
    await expect(page.getByTestId('detail-meta')).toContainText('Ana');
  });

  test('7. la página del equipo muestra exactamente 2 tarjetas', async ({ page }) => {
    await page.goto('/equipo');
    await expect(page.getByTestId('developer-card')).toHaveCount(2);
    await expect(page.getByTestId('team-grid')).toContainText('Ana Torres');
    await expect(page.getByTestId('team-grid')).toContainText('Luis Ramírez');
  });

  test('8. el formulario rechaza datos inválidos', async ({ page }) => {
    await page.goto('/contacto');
    await page.getByTestId('contact-name').fill('A');
    await page.getByTestId('contact-email').fill('correo-malo');
    await page.getByTestId('contact-message').fill('corto');
    await page.getByTestId('contact-submit').click();
    await expect(page.getByTestId('contact-error')).toContainText('correo válido');
    await expect(page.getByTestId('contact-success')).toHaveCount(0);
  });

  test('9. el formulario acepta un mensaje válido', async ({ page }) => {
    await page.goto('/contacto');
    await page.getByTestId('contact-name').fill('Marta');
    await page.getByTestId('contact-email').fill('marta@example.com');
    await page.getByTestId('contact-message').fill('Me gustaría hablar sobre un MVP.');
    await page.getByTestId('contact-submit').click();
    await expect(page.getByTestId('contact-success')).toContainText('Mensaje recibido');
  });

  test('10. la API expone health y desarrolladores', async ({ request }) => {
    const health = await request.get('/api/health');
    expect(health.ok()).toBeTruthy();
    expect((await health.json()).status).toBe('ok');

    const developers = await request.get('/api/developers');
    expect((await developers.json())).toHaveLength(2);
  });

  test('11. el footer muestra el año actual', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByTestId('footer-year')).toContainText(String(new Date().getFullYear()));
  });
});
