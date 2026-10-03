/** @type {import('tailwindcss').Config} */
export default {
  // Dark mode is driven by a `dark` class on a root element (Req 1.1, 26.2),
  // toggled by the Theme_Toggle rather than the OS media query.
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
};
