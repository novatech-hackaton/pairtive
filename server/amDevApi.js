// Local development emulator for the Vercel /api functions.
// `npm run dev` serves /api/<name> by loading api/<name>.js through Vite's SSR loader,
// so the whole app works locally without the Vercel CLI. Production uses Vercel itself.

function amReadBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => {
      data += chunk;
      if (data.length > 1_000_000) reject(new Error('Body too large'));
    });
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });
}

export function amDevApiPlugin() {
  return {
    name: 'am-dev-api',
    apply: 'serve',
    configureServer(server) {
      server.middlewares.use(async (req, res, next) => {
        const url = new URL(req.url, 'http://localhost');
        const match = url.pathname.match(/^\/api\/(am[A-Za-z0-9]+)$/);
        if (!match) return next();

        try {
          const mod = await server.ssrLoadModule(`/api/${match[1]}.js`);
          const raw = await amReadBody(req);
          let body = {};
          if (raw) {
            try {
              body = JSON.parse(raw);
            } catch {
              body = raw;
            }
          }
          req.body = body;
          req.query = Object.fromEntries(url.searchParams);

          res.status = (code) => {
            res.statusCode = code;
            return res;
          };
          res.json = (payload) => {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(payload));
            return res;
          };
          res.send = (payload) => {
            res.end(typeof payload === 'string' ? payload : JSON.stringify(payload));
            return res;
          };

          await mod.default(req, res);
        } catch (err) {
          if (err?.code === 'ERR_LOAD_URL' || /Failed to load/.test(String(err?.message))) return next();
          console.error('[am-dev-api]', err);
          res.statusCode = 500;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ error: 'Internal error' }));
        }
      });
    },
  };
}
