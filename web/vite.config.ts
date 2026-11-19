import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  base: './',
  plugins: [react()],
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    rollupOptions: {
      // index.html = in-game overlay, phone.html = tracker app for phones
      input: { main: 'index.html', phone: 'phone.html' },
    },
  },
})
