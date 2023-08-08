import path from "path"
import { defineConfig } from "vite"

import react from "@vitejs/plugin-react"
import dts from "vite-plugin-dts"

module.exports = defineConfig({
  plugins: [
    react(),
    dts({
      insertTypesEntry: true,
    }),
  ],
  build: {
    lib: {
      entry: path.resolve(__dirname, "src/index.ts"),
      name: "audiences",
      fileName: (format) => `audiences.${format}.js`,
    },
    rollupOptions: {
      external: ["react", "react-dom", "playbook-ui"],
    },
  },
})
