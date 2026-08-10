// Canopy demo UI mode: axios adapter that answers from hardcoded data.
//
// Installed onto the axios instance in store/api.js when isDemoMode is true, so
// every request the app makes is resolved locally with no BMC. GETs return the
// canned payload for the request path (see demoData.js) or a permissive empty
// collection; a login POST returns a fake session; other writes succeed no-op.
import demoResponses from './demoData';

// Normalize a request URL to a demoData key: drop origin, query string and any
// trailing slash (so '/redfish/v1/' and '/redfish/v1?$expand=*' both match).
function normalizePath(url) {
  let path = url || '';
  const scheme = path.indexOf('://');
  if (scheme >= 0) {
    const slash = path.indexOf('/', scheme + 3);
    path = slash >= 0 ? path.slice(slash) : '/';
  }
  const q = path.indexOf('?');
  if (q >= 0) path = path.slice(0, q);
  if (path.length > 1 && path.endsWith('/')) path = path.slice(0, -1);
  return path;
}

function resolveValue(entry, config) {
  return typeof entry === 'function' ? entry(config) : entry;
}

// Deep-resolve any function-valued leaves (e.g. DateTime: () => now).
function materialize(value, config) {
  if (typeof value === 'function') return value(config);
  if (Array.isArray(value)) return value.map((v) => materialize(v, config));
  if (value && typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) out[k] = materialize(v, config);
    return out;
  }
  return value;
}

export default function mockAdapter(config) {
  const method = (config.method || 'get').toLowerCase();
  const path = normalizePath(config.url);

  const respond = (data, extraHeaders = {}, status = 200) =>
    Promise.resolve({
      data,
      status,
      statusText: 'OK',
      headers: { 'content-type': 'application/json', ...extraHeaders },
      config,
      request: {},
    });

  if (method === 'get') {
    const entry = demoResponses[path];
    if (entry !== undefined) {
      return respond(materialize(resolveValue(entry, config), config));
    }
    // Unknown endpoint: empty collection is harmless for list views.
    return respond({
      '@odata.id': path,
      Members: [],
      'Members@odata.count': 0,
    });
  }

  // Fake a Redfish session on login so the standard login flow also works.
  if (method === 'post' && path.endsWith('/SessionService/Sessions')) {
    return respond(
      {
        '@odata.id': '/redfish/v1/SessionService/Sessions/demo',
        Id: 'demo',
        UserName: 'demo',
        Roles: ['Administrator'],
      },
      {
        'x-auth-token': 'canopy-demo-token',
        location: '/redfish/v1/SessionService/Sessions/demo',
      },
    );
  }

  // Any other write (patch/post/put/delete) succeeds as a no-op.
  return respond({});
}
