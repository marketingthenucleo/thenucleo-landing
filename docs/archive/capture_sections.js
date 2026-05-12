const { chromium } = require('playwright');
const path = require('path');

const OUTPUT_DIR = 'c:/Users/Benjamin/Desktop/Claude/App The Nucleo MCP integral/Design/screenshots-app';
const URL = 'https://work.thenucleo.com/';

const MOBILE_SECTIONS = [
  { name: '01_hero',             scroll_y: 0 },
  { name: '02_que_incluye',      scroll_y: 700 },
  { name: '03_resultados_reales',scroll_y: 1800 },
  { name: '04_plataforma',       scroll_y: 2800 },
  { name: '05_precios',          scroll_y: 3800 },
  { name: '06_cta_footer',       scroll_y: 5500 },
];

(async () => {
  const browser = await chromium.launch();

  // ---- MOBILE 375x812 ----
  console.log('--- Capturing Mobile 375x812 ---');
  const mobilePage = await browser.newPage({ viewport: { width: 375, height: 812 } });
  await mobilePage.goto(URL, { waitUntil: 'networkidle', timeout: 30000 });
  await mobilePage.waitForTimeout(2000);

  const fullHeight = await mobilePage.evaluate(() => document.body.scrollHeight);
  console.log(`Mobile full page height: ${fullHeight}px`);

  for (const section of MOBILE_SECTIONS) {
    const scrollY = Math.min(section.scroll_y, Math.max(0, fullHeight - 812));
    await mobilePage.evaluate((y) => window.scrollTo(0, y), scrollY);
    await mobilePage.waitForTimeout(800);
    const filePath = path.join(OUTPUT_DIR, `mobile_${section.name}.png`);
    await mobilePage.screenshot({ path: filePath, fullPage: false });
    console.log(`Saved: ${filePath}`);
  }

  await mobilePage.close();

  // ---- TABLET 768x1024 ----
  console.log('--- Capturing Tablet 768x1024 ---');
  const tabletPage = await browser.newPage({ viewport: { width: 768, height: 1024 } });
  await tabletPage.goto(URL, { waitUntil: 'networkidle', timeout: 30000 });
  await tabletPage.waitForTimeout(2000);

  const fullHeightTablet = await tabletPage.evaluate(() => document.body.scrollHeight);
  console.log(`Tablet full page height: ${fullHeightTablet}px`);

  await tabletPage.evaluate(() => window.scrollTo(0, 0));
  await tabletPage.waitForTimeout(800);
  const tabletHeroPath = path.join(OUTPUT_DIR, 'tablet_01_hero.png');
  await tabletPage.screenshot({ path: tabletHeroPath, fullPage: false });
  console.log(`Saved: ${tabletHeroPath}`);

  // Also capture a few key tablet sections
  const tabletSections = [
    { name: '02_que_incluye', scroll_y: 700 },
    { name: '05_precios',     scroll_y: 3500 },
  ];
  for (const section of tabletSections) {
    const scrollY = Math.min(section.scroll_y, Math.max(0, fullHeightTablet - 1024));
    await tabletPage.evaluate((y) => window.scrollTo(0, y), scrollY);
    await tabletPage.waitForTimeout(800);
    const filePath = path.join(OUTPUT_DIR, `tablet_${section.name}.png`);
    await tabletPage.screenshot({ path: filePath, fullPage: false });
    console.log(`Saved: ${filePath}`);
  }

  await tabletPage.close();
  await browser.close();
  console.log('Done.');
})();
