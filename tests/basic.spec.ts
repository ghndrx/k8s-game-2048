import { test, expect } from '@playwright/test';

test.describe('2048 Game - Basic Functionality', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
  });

  test('should load the game successfully', async ({ page }) => {
    // Check title
    await expect(page).toHaveTitle(/2048/);
    
    // Check main elements are present
    await expect(page.locator('h1')).toContainText('2048');
    await expect(page.locator('.game-container')).toBeVisible();
    await expect(page.locator('.grid-container')).toBeVisible();
    
    // Check score displays
    await expect(page.locator('#score')).toBeVisible();
    await expect(page.locator('#best')).toBeVisible();
  });

  test('should show environment badge', async ({ page }) => {
    const envBadge = page.locator('#env-badge');
    await expect(envBadge).toBeVisible();
    
    // Should have one of the environment classes
    const badgeClass = await envBadge.getAttribute('class');
    expect(badgeClass).toMatch(/(development|staging|production)/);
  });

  test('should have initial tiles on game start', async ({ page }) => {
    // Should have at least 2 tiles initially
    const tiles = page.locator('.tile');
    await expect(tiles).toHaveCount(2);
    
    // Tiles should have values 2 or 4
    const tileTexts = await tiles.allTextContents();
    tileTexts.forEach(text => {
      expect(['2', '4']).toContain(text);
    });
  });

  test('should restart game when restart button is clicked', async ({ page }) => {
    const restartButton = page.locator('#restart-button');
    await expect(restartButton).toBeVisible();
    
    // Click restart
    await restartButton.click();
    
    // Should have exactly 2 tiles after restart
    const tiles = page.locator('.tile');
    await expect(tiles).toHaveCount(2);
    
    // Score should be reset to 0
    await expect(page.locator('#score')).toHaveText('0');
  });
});
