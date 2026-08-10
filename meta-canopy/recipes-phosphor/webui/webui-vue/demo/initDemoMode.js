// Canopy demo UI mode: seed an authenticated session so the app skips login and
// lands on the dashboard with hardcoded data. Called from main.js before mount.
import { isDemoMode } from './config';

export default function initDemoMode(store) {
  if (!isDemoMode) return;

  // Mark as logged in. With no XSRF-TOKEN cookie present, authSuccess falls back
  // to the header-token path (xAuthToken), which makes isLoggedIn true.
  store.commit('authentication/authSuccess', {
    session: '/redfish/v1/SessionService/Sessions/demo',
    token: 'canopy-demo-token',
  });

  // Give the session an admin role so the router's auth guard lets us through
  // without an extra privilege round-trip.
  store.commit('global/setSessionRole', 'Administrator');
  store.commit('global/setUsername', 'demo');
}
