import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#0066ff',
          700: '#0052cc',
          800: '#003d99',
          900: '#0a1d37',
          950: '#061226',
        },
      },
      fontFamily: {
        sans: ['var(--font-jakarta)', 'system-ui', 'sans-serif'],
        hand: ['var(--font-caveat)', 'cursive'],
      },
      maxWidth: {
        page: '1200px',
      },
      boxShadow: {
        card: '0 1px 3px rgba(15, 27, 51, 0.06), 0 8px 24px rgba(15, 27, 51, 0.04)',
      },
    },
  },
  plugins: [],
};

export default config;
