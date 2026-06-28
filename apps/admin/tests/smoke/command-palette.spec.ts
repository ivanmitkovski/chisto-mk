import { authenticatedTest as test, expect } from '../fixtures/authenticated.fixture';

test.describe('Command palette', () => {
  test('opens from header trigger and closes with Escape', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/);
    await expect(page.locator('#admin-main')).toBeVisible({ timeout: 15_000 });

    const trigger = page.getByRole('textbox', { name: /open command palette/i });
    await expect(trigger).toBeVisible();
    await trigger.click();

    const palette = page.getByRole('dialog', { name: /command palette/i });
    await expect(palette).toBeVisible();

    const query = page.getByRole('combobox', { name: /search commands/i });
    await expect(query).toBeFocused();

    await page.keyboard.press('Escape');
    await expect(palette).toBeHidden();
  });

  test('reopens with keyboard shortcut after Escape', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/);
    await expect(page.locator('#admin-main')).toBeVisible({ timeout: 15_000 });

    const trigger = page.getByRole('textbox', { name: /open command palette/i });
    await trigger.click();
    await expect(page.getByRole('dialog', { name: /command palette/i })).toBeVisible();
    await page.keyboard.press('Escape');
    await expect(page.getByRole('dialog', { name: /command palette/i })).toBeHidden();

    const modifier = process.platform === 'darwin' ? 'Meta' : 'Control';
    await page.keyboard.press(`${modifier}+KeyK`);
    await expect(page.getByRole('dialog', { name: /command palette/i })).toBeVisible();
    await expect(page.getByRole('combobox', { name: /search commands/i })).toBeFocused();
  });

  test('filters results when typing a query', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard');
    await expect(page.locator('#admin-main')).toBeVisible({ timeout: 15_000 });
    await page.getByRole('textbox', { name: /open command palette/i }).click();

    const query = page.getByRole('combobox', { name: /search commands/i });
    await query.fill('reports');

    await expect(page.getByRole('listbox', { name: /available commands/i })).toBeVisible();
    await expect(page.getByRole('option').first()).toBeVisible();
  });
});
