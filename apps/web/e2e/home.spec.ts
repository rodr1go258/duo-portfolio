import { expect, test } from '@playwright/test';

test.describe('Navegación y portada', () => {
  test('1. la portada muestra el título y las métricas del equipo', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByTestId('home-title')).toHaveText('Dos mentes. Un producto.');
    await expect(page.getByTestId('stat-team')).toHaveText('2');
    await expect(page.getByTestId('brand')).toBeVisible();
  });

  test('2. el CTA lleva al catálogo de proyectos', async ({ page }) => {
    await page.goto('/');
    await page.getByTestId('cta-projects').click();
    await expect(page).toHaveURL(/\/proyectos$/);
    await expect(page.getByTestId('projects-title')).toBeVisible();
  });

  test('3. la barra de navegación permite ir a equipo y contacto', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('link', { name: 'Equipo' }).click();
    await expect(page.getByTestId('team-title')).toBeVisible();
    await page.getByRole('link', { name: 'Contacto' }).click();
    await expect(page.getByTestId('contact-title')).toBeVisible();
  });

  test('4. una ruta desconocida muestra la página 404', async ({ page }) => {
    await page.goto('/ruta-inexistente');
    await expect(page.getByTestId('not-found-title')).toHaveText('Esta página no existe');
  });
});
