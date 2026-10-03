import { loadEnv } from 'vite';
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { amDevApiPlugin } from './server/amDevApi.js';

export default defineConfig(({ mode }) => {
  // Expose every .env value to process.env so the local /api emulator can read
  // server-only secrets (they are never bundled into the client).
  const env = loadEnv(mode, process.cwd(), '');
  for (const [key, value] of Object.entries(env)) {
    if (process.env[key] === undefined) process.env[key] = value;
  }

  return {
    plugins: [react(), tailwindcss(), amDevApiPlugin()],
    test: {
      environment: 'jsdom',
      globals: true,
      setupFiles: ['./tests/amSetupTests.js'],
      include: ['shared/**/*.test.{js,jsx}', 'src/**/*.test.{js,jsx}', 'tests/**/*.test.{js,jsx}'],
      css: false,
    },
  };
});
