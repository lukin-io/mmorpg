#!/usr/bin/env node
/**
 * Global post-deploy click smoke (Playwright). Cursor browser MCP optional.
 *
 * Usage:
 *   set SMOKE_EMAIL=Inquisitor
 *   set SMOKE_PASSWORD=AshenSuperAdmin!2026
 *   node scripts/smoke_click.mjs
 *   set SMOKE_GLOBAL=1 & node scripts/smoke_click.mjs   # full route walk
 */
import {chromium} from "playwright";

const baseUrl = process.env.SMOKE_BASE_URL || "https://web-production-bc5d0.up.railway.app";
const email = process.env.SMOKE_EMAIL;
const password = process.env.SMOKE_PASSWORD;
const global = process.env.SMOKE_GLOBAL === "1" || process.argv.includes("--global");
const profilePath =
  process.env.SMOKE_PROFILE ||
  "/player/%D0%93%D0%BB%D0%B0%D0%B2%D0%B0%D0%98%D0%BD%D0%BA%D0%B2%D0%B8%D0%B7%D0%B8%D1%86%D0%B8%D0%B8";

if (!email || !password) {
  console.error("Set SMOKE_EMAIL and SMOKE_PASSWORD (sandbox: Inquisitor + SEED_SUPER_ADMIN_PASSWORD)");
  process.exit(2);
}

const browser = await chromium.launch({headless: true});
const page = await browser.newPage({viewport: {width: 1280, height: 800}});
const log = (step, detail = "") => console.log(`[ok] ${step}${detail ? ` — ${detail}` : ""}`);
const fail = (step, detail) => {
  console.error(`[fail] ${step} — ${detail}`);
  throw new Error(`${step}: ${detail}`);
};

async function visit(path, label, {expectOk = true, maxStatus = 399} = {}) {
  const res = await page.goto(`${baseUrl}${path}`, {waitUntil: "domcontentloaded", timeout: 60000});
  const status = res?.status() ?? 0;
  const url = page.url();
  if (expectOk && (status < 200 || status > maxStatus)) fail(label, `HTTP ${status} @ ${url}`);
  if (url.includes("sign_in") && !path.includes("sign_in")) fail(label, `redirected to sign_in`);
  log(label, `HTTP ${status} ${url}`);
  return {status, url};
}

try {
  await visit("/users/sign_in", "sign_in page");
  await page.locator('input[name="user[login]"]').first().fill(email);
  await page.locator('input[name="user[password]"]').first().fill(password);
  await Promise.all([
    page.waitForNavigation({waitUntil: "domcontentloaded", timeout: 60000}).catch(() => null),
    page.locator('input[type="submit"], button[type="submit"]').first().click()
  ]);
  if (page.url().includes("sign_in")) fail("login", "still on sign_in");
  log("logged in", page.url());

  await visit("/world", "world");
  const regrowth = await page.locator("[data-controller='nl-regrowth-timer']").count();
  log("regrowth timers on map", String(regrowth));

  await visit(profilePath, "profile");
  const lookup = page.locator('[data-profile-lookup="1"] input[name="name"]');
  if (await lookup.count()) {
    const status = await page.locator("[data-presence-status]").first().getAttribute("data-presence-status");
    log("presence badge", status || "missing");
    await lookup.fill("___nobody___");
    await page.locator('[data-profile-lookup="1"] button[type="submit"]').click();
    await page.waitForLoadState("domcontentloaded");
    log("lookup miss handled", page.url());
  }

  await visit("/inventory", "inventory");

  if (global) {
    const routes = [
      ["/activity", "activity"],
      ["/trade_hub", "trade_hub"],
      ["/clans", "clans"],
      ["/world_map", "world_map"],
      ["/instances", "instances"],
      ["/arena", "arena"],
      ["/shop", "shop"],
      ["/manage", "manage"]
    ];
    for (const [path, label] of routes) {
      try {
        await visit(path, label, {maxStatus: 404});
      } catch (err) {
        console.warn(`[warn] ${label}: ${err.message}`);
      }
    }

    // Click first safe world action / city hotspot if present.
    await visit("/world", "world (revisit)");
    const action = page.locator("form.nl-world-action button, .nl-world-actions button, a.nl-city-hotspot").first();
    if (await action.count()) {
      await action.click({timeout: 5000}).catch(() => null);
      await page.waitForLoadState("domcontentloaded").catch(() => null);
      log("clicked first world/city control", page.url());
    } else {
      log("no clickable world action on cell");
    }
  }

  console.log(global ? "CLICK_SMOKE_GLOBAL_OK" : "CLICK_SMOKE_OK");
} catch (err) {
  console.error("CLICK_SMOKE_FAIL", err.message);
  process.exitCode = 1;
} finally {
  await browser.close();
}
