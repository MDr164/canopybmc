// Canopy demo UI mode flag (runtime toggle).
//
// Demo mode makes the WebUI serve hardcoded Redfish data from a mock axios
// adapter and auto-authenticate, so the dashboard renders with no BMC. It is
// toggled at runtime from Settings > Demo mode (see views/Settings/DemoMode),
// persisted in localStorage, and applied on the next page load. See demoData.js,
// mockAdapter.js and initDemoMode.js.
//
// Resolution order:
//   1. localStorage 'canopyDemoMode' ('true' | 'false') - set by the toggle
//   2. build-time default VITE_DEMO_MODE (used by the local dev preview)
const STORAGE_KEY = 'canopyDemoMode';

function resolveDemoMode() {
  try {
    const stored = window.localStorage.getItem(STORAGE_KEY);
    if (stored === 'true') return true;
    if (stored === 'false') return false;
  } catch {
    // localStorage unavailable (SSR/tests): fall through to the build default.
  }
  return import.meta.env.VITE_DEMO_MODE === 'true';
}

// Evaluated once at load; toggling persists and reloads so this re-resolves.
export const isDemoMode = resolveDemoMode();

// Persist the demo-mode choice. The caller is expected to reload the page so
// the mock adapter and auth seeding take effect from boot.
export function setDemoMode(enabled) {
  try {
    window.localStorage.setItem(STORAGE_KEY, enabled ? 'true' : 'false');
  } catch {
    // ignore write failures (private mode, etc.)
  }
}
