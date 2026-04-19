# enfr — Claude Code Notes

## Project Structure

Flutter app in `enfr/` subdirectory. GitHub Pages deployment at `https://mrhockeymonkey.github.io/enfr`.

- `enfr/lib/` — Dart source
- `enfr/web/` — Web-specific files (index.html, flutter_bootstrap.js)
- `enfr/assets/verbs.yaml` — Verb conjugation data
- `.github/workflows/build.yml` — CI: builds web with `--base-href /enfr/` and deploys to `gh-pages` branch

## Testing the App Locally with Playwright MCP

The Playwright MCP tools (`mcp__playwright__browser_*`) are the primary way to get visual feedback on UI changes. Follow these steps at the start of each session:

### 1. Fix the Chrome symlink (required each session)

The Playwright MCP server expects Chrome at `/opt/google/chrome/chrome`, but the actual binary is elsewhere:

```bash
mkdir -p /opt/google/chrome
ln -sf /opt/pw-browsers/chromium-1194/chrome-linux/chrome /opt/google/chrome/chrome
```

### 2. Build the Flutter web app

For local testing (no base-href needed):
```bash
cd enfr && flutter build web
```

For a production-equivalent build matching GitHub Pages:
```bash
cd enfr && flutter build web --base-href /enfr/
```

### 3. Start a local HTTP server

```bash
python3 -m http.server 8080 --directory enfr/build/web &
```

Verify it's up: `curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/` should return `200`.

### 4. Navigate and inspect with Playwright MCP

```
mcp__playwright__browser_navigate  → http://localhost:8080
mcp__playwright__browser_take_screenshot
mcp__playwright__browser_console_messages (level: "error")
mcp__playwright__browser_snapshot
```

### Known Environment Limitations

- **Roboto font** fails to load (`fonts.gstatic.com` is network-restricted in this environment) — cosmetic only, not a real bug.
- **External API calls** (Mistral AI) will fail — test UI flow only, not AI responses.
- The HTTP server process is killed on session resume — restart it each time.
- The Chrome symlink persists across session resumes (no need to recreate if it already exists).

## CanvasKit: Local vs CDN

`enfr/web/flutter_bootstrap.js` forces local CanvasKit:

```js
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
```

Without this, Flutter loads CanvasKit from `gstatic.com` CDN. If that fails (network restrictions, firewalls), the app shows a **blank white screen** with no fallback. The locally bundled `canvaskit/` directory is the fix.

## CI / Deployment

Merges to `main` trigger `.github/workflows/build.yml` which:
1. Builds with `flutter build web --base-href /enfr/`
2. Deploys `enfr/build/web/` to the `gh-pages` branch via `peaceiris/actions-gh-pages`

GitHub Pages serves from the `gh-pages` branch root.
