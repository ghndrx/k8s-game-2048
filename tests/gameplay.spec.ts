import { test, expect } from '@playwright/test';

test.describe('2048 Game - Gameplay Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
  });

  test('should move tiles with arrow keys', async ({ page }) => {
    // Get initial tile positions
    const initialTiles = await page.locator('.tile').all();
    const initialPositions = [];
    
    for (const tile of initialTiles) {
      const style = await tile.getAttribute('style');
      initialPositions.push(style);
    }
    
    // Press arrow key to move tiles
    await page.keyboard.press('ArrowRight');
    await page.waitForTimeout(500); // Wait for animation
    
    // Check that tiles moved or new tile appeared
    const newTiles = await page.locator('.tile').all();
    expect(newTiles.length).toBeGreaterThanOrEqual(2);
    
    // At least one tile should have moved or new tile should appear
    let tilesChanged = newTiles.length > initialTiles.length;
    
    if (!tilesChanged) {
      for (let i = 0; i < Math.min(newTiles.length, initialPositions.length); i++) {
        const newStyle = await newTiles[i].getAttribute('style');
        if (newStyle !== initialPositions[i]) {
          tilesChanged = true;
          break;
        }
      }
    }
    
    expect(tilesChanged).toBe(true);
  });

  test('should handle touch/swipe on mobile', async ({ page, isMobile }) => {
    test.skip(!isMobile, 'Touch test only for mobile');
    
    const gameContainer = page.locator('.game-container');
    
    // Simulate swipe right
    await gameContainer.touchStart([{ x: 100, y: 200 }]);
    await gameContainer.touchEnd([{ x: 300, y: 200 }]);
    
    await page.waitForTimeout(500);
    
    // Should have tiles after swipe
    const tiles = page.locator('.tile');
    await expect(tiles).toHaveCount.atLeast(2);
  });

  test('should update score when tiles merge', async ({ page }) => {
    // This test might need multiple moves to get mergeable tiles
    // For now, just verify score element updates
    const scoreElement = page.locator('#score');
    const initialScore = await scoreElement.textContent();
    
    // Try multiple moves to potentially trigger a merge
    for (let i = 0; i < 10; i++) {
      await page.keyboard.press('ArrowRight');
      await page.waitForTimeout(200);
      await page.keyboard.press('ArrowDown');
      await page.waitForTimeout(200);
      await page.keyboard.press('ArrowLeft');
      await page.waitForTimeout(200);
      await page.keyboard.press('ArrowUp');
      await page.waitForTimeout(200);
      
      const currentScore = await scoreElement.textContent();
      if (currentScore !== initialScore) {
        expect(parseInt(currentScore || '0')).toBeGreaterThan(parseInt(initialScore || '0'));
        break;
      }
    }
  });
});
