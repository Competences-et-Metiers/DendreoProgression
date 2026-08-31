/** @type {import('tailwindcss').Config} */
// Mirrors the config that previously lived inline in public/index.html alongside
// the cdn.tailwindcss.com script. That CDN build is the browser-side JIT compiler:
// it recompiled the whole stylesheet in JavaScript on every DOM mutation, which is
// why navigation felt slow. This config drives a static build instead (see the
// build:css script in package.json).
module.exports = {
  darkMode: 'class',
  content: ['./src/**/*.{js,jsx,ts,tsx}', './public/index.html'],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
      },
    },
  },
  plugins: [],
};
