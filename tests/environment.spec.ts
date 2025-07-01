import { test, expect } from '@playwright/test';

test.describe('2048 Game - Environment Tests', () => {
  test('should display correct environment in development', async ({ page }) => {
    // This test will run when BASE_URL contains 'dev'
    const baseUrl = process.env.BASE_URL || '';
    test.skip(!baseUrl.includes('dev'), 'Development environment test');
    
    await page.goto('/');
    
    const envElement = page.locator('#environment');
    await expect(envElement).toContainText('Development');
    
    const envBadge = page.locator('#env-badge');
    await expect(envBadge).toHaveClass(/development/);
  });

  test('should display correct environment in staging', async ({ page }) => {
    const baseUrl = process.env.BASE_URL || '';
    test.skip(!baseUrl.includes('staging'), 'Staging environment test');
    
    await page.goto('/');
    
    const envElement = page.locator('#environment');
    await expect(envElement).toContainText('Staging');
    
    const envBadge = page.locator('#env-badge');
    await expect(envBadge).toHaveClass(/staging/);
  });

  test('should display correct environment in production', async ({ page }) => {
    const baseUrl = process.env.BASE_URL || '';
    test.skip(baseUrl.includes('dev') || baseUrl.includes('staging'), 'Production environment test');
    
    await page.goto('/');
    
    const envElement = page.locator('#environment');
    await expect(envElement).toContainText('Production');
    
    const envBadge = page.locator('#env-badge');
    await expect(envBadge).toHaveClass(/production/);
  });

  test('should have working health endpoint', async ({ request }) => {
    const response = await request.get('/health');
    expect(response.status()).toBe(200);
    
    const text = await response.text();
    expect(text).toContain('healthy');
  });

  test('should load all assets successfully', async ({ page }) => {
    const responses: any[] = [];
    
    page.on('response', response => {
      responses.push(response);
    });
    
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Check that all resources loaded successfully
    const failedResponses = responses.filter(response => response.status() >= 400);
    expect(failedResponses.length).toBe(0);
  });

  test('should have correct security headers', async ({ request }) => {
    const response = await request.get('/');
    
    // Check for basic security headers
    expect(response.headers()['x-frame-options']).toBeDefined();
    expect(response.headers()['x-content-type-options']).toBeDefined();
    expect(response.headers()['x-xss-protection']).toBeDefined();
  });
});
