/**
 * Global type declarations
 */

// Plotly.js loaded from CDN exposes itself as window.Plotly
// This allows TypeScript to recognize the global object
declare global {
  interface Window {
    Plotly: typeof import('plotly.js');
  }
}

export {};
