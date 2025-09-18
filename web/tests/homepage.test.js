// Simple test to verify the Next.js application works correctly
import { test, expect } from '@playwright/test';

test('should display the Knowledge Base homepage', async ({ page }) => {
  await page.goto('http://localhost:3000');
  
  // Check that the main heading is present
  await expect(page.getByText('Knowledge Base')).toBeVisible();
  
  // Check that navigation categories are present
  await expect(page.getByText('Documents')).toBeVisible();
  await expect(page.getByText('Scripts')).toBeVisible();
  await expect(page.getByText('Configurations')).toBeVisible();
  await expect(page.getByText('Projects')).toBeVisible();
  await expect(page.getByText('Tasks')).toBeVisible();
  
  // Check that file listings are present
  await expect(page.getByText('Installation Guide.md')).toBeVisible();
  await expect(page.getByText('deploy.sh')).toBeVisible();
  await expect(page.getByText('database.yml')).toBeVisible();
});

test('should allow searching for files', async ({ page }) => {
  await page.goto('http://localhost:3000');
  
  // Fill in the search box
  await page.fill('input[placeholder="Search files..."]', 'Installation');
  
  // Click the search button
  await page.click('button:has-text("Search")');
  
  // Check that the search results are displayed
  await expect(page.getByText('Installation Guide.md')).toBeVisible();
});