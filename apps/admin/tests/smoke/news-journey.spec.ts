import { authenticatedTest as test, expect } from '../fixtures/authenticated.fixture';

async function waitForNewsPostPatch(page: import('@playwright/test').Page, postId?: string) {
  await page.waitForResponse(
    (response) => {
      if (response.request().method() !== 'PATCH' || !response.ok()) return false;
      const pathname = new URL(response.url()).pathname;
      if (!/\/admin\/news\/posts\/[^/]+$/.test(pathname)) return false;
      return postId ? pathname.endsWith(`/${postId}`) : true;
    },
    { timeout: 30_000 },
  );
}

test.describe('News admin smoke', () => {
  test('news list loads for authenticated admin', async ({ authenticatedPage: page }) => {
    await page.goto('/dashboard/news');
    await page.waitForURL('**/dashboard/news**');
    await expect(page.getByRole('heading', { name: /news/i }).first()).toBeVisible();
  });

  test('draft editor: create, edit body, autosave, and preview', async ({
    authenticatedPage: page,
  }) => {
    test.setTimeout(120_000);

    const title = `Smoke test draft ${Date.now()}`;

    await page.goto('/dashboard/news/new');
    const titleField = page.getByRole('textbox', { name: /^title$/i });
    await expect(titleField).toBeVisible({ timeout: 15_000 });
    await titleField.fill(title);

    const createResponse = page.waitForResponse(
      (response) =>
        response.request().method() === 'POST' &&
        /\/admin\/news\/posts$/.test(new URL(response.url()).pathname) &&
        response.status() === 201,
    );
    await page.getByRole('button', { name: /create draft/i }).click();
    await createResponse;
    await expect(page).toHaveURL(/\/dashboard\/news\/(?!new)/, { timeout: 30_000 });

    const postId = page.url().split('/').pop() ?? '';
    expect(postId).toBeTruthy();

    await expect(page.getByRole('button', { name: 'Publish', exact: true })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Paste body', exact: true })).toBeVisible({
      timeout: 15_000,
    });

    await expect(page.getByRole('button', { name: 'Insert', exact: true })).toBeVisible({
      timeout: 20_000,
    });
    await page.getByRole('button', { name: 'Insert', exact: true }).click();
    await page.getByRole('menuitem', { name: /Add heading/ }).click();

    const headingInput = page.getByPlaceholder('Heading text');
    await expect(headingInput).toBeVisible();
    await headingInput.fill('Smoke section');
    await headingInput.press('Enter');

    const bodyEditor = page.locator('.ProseMirror').last();
    await expect(bodyEditor).toBeVisible({ timeout: 10_000 });
    await bodyEditor.click();

    const patchPromise = waitForNewsPostPatch(page, postId);
    await bodyEditor.pressSequentially('Body copy written by the smoke test.', { delay: 10 });

    const saveButton = page.getByRole('button', { name: 'Save draft', exact: true });
    if (await saveButton.isEnabled()) {
      await saveButton.click();
    } else {
      await expect(page.getByText('Saved just now')).toBeVisible({ timeout: 30_000 });
    }
    await patchPromise;

    await page.reload();
    await expect(page.getByPlaceholder('Heading text')).toHaveValue('Smoke section', {
      timeout: 20_000,
    });
    await expect(page.getByText('Body copy written by the smoke test.')).toBeVisible();

    await page.getByRole('tab', { name: 'Preview', exact: true }).click();
    await expect(page.getByText('Draft preview')).toBeVisible();
    await expect(
      page.getByRole('heading', { name: 'Smoke section', exact: true }),
    ).toBeVisible();
    await expect(page.getByText('Body copy written by the smoke test.')).toBeVisible();
  });
});
