import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    rollupOptions: {
      // Externalize plotly.js - load from CDN instead of bundling
      // This dramatically reduces build time and memory usage on Raspberry Pi
      external: ['plotly.js-dist-min'],
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          grid: ['ag-grid-community', 'ag-grid-react'],
        },
        globals: {
          'plotly.js-dist-min': 'Plotly',
        },
      },
    },
  },
  resolve: {
    alias: {
      // Redirect plotly.js imports to the minified dist version
      'plotly.js': 'plotly.js-dist-min',
    },
  },
});
