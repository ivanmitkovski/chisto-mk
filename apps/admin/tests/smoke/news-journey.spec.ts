import { authenticatedTest as test, expect } from '../fixtures/authenticated.fixture';

test.describe('News admin smoke', () => {
  test.describe.configure({ mode: 'serial' });

  test('news list loads for authenticated admin', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard/news');
    await page.waitForURL('**/dashboard/news**');
    await expect(page.getByRole('heading', { name: /news/i }).first()).toBeVisible();
  });

  test('create draft and open editor', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard/news/new');
    const titleField = page.getByRole('textbox', { name: /^title$/i });
    await expect(titleField).toBeVisible({ timeout: 15_000 });
    await titleField.fill('Smoke test draft');
    await page.getByRole('button', { name: /create draft/i }).click();
    await page.waitForURL(/\/dashboard\/news\/(?!new)/);
    await expect(page.getByRole('heading').first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'Publish', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Update', exact: true })).toHaveCount(0);
    await expect(page.getByRole('button', { name: 'Paste body', exact: true })).toBeVisible();
  });

  test('edit draft body: heading + paragraph persist across save and reload', async ({
    authenticatedPage: page,
  }) => {
    // Re-open the draft created in the previous serial test.
    await page.goto('/dashboard/news');
    await page.getByRole('link', { name: 'Smoke test draft' }).first().click();
    await page.waitForURL(/\/dashboard\/news\/(?!new)/);

    // Insert a heading block from the document toolbar.
    await page.getByRole('button', { name: /^Insert/ }).click();
    await page.getByRole('menuitem', { name: /Add heading/ }).click();
    const headingInput = page.getByPlaceholder('Heading text');
    await expect(headingInput).toBeVisible();
    await headingInput.fill('Smoke section');

    // Enter after a heading starts a fresh paragraph; type into it.
    await headingInput.press('Enter');
    await page.keyboard.type('Body copy written by the smoke test.');

    await page.getByRole('button', { name: 'Save draft', exact: true }).click();
    await expect(page.getByText('Post saved')).toBeVisible({ timeout: 15_000 });

    await page.reload();
    await expect(page.getByPlaceholder('Heading text')).toHaveValue('Smoke section', {
      timeout: 15_000,
    });
    await expect(page.getByText('Body copy written by the smoke test.')).toBeVisible();
  });

  test('preview tab renders draft content with watermark', async ({
    authenticatedPage: page,
  }) => {
    await page.goto('/dashboard/news');
    await page.getByRole('link', { name: 'Smoke test draft' }).first().click();
    await page.waitForURL(/\/dashboard\/news\/(?!new)/);

    await page.getByRole('tab', { name: 'Preview', exact: true }).click();
    await expect(page.getByText('Draft preview')).toBeVisible();
    await expect(
      page.getByRole('heading', { name: 'Smoke section', exact: true }),
    ).toBeVisible();
    await expect(page.getByText('Body copy written by the smoke test.')).toBeVisible();
  });
});

