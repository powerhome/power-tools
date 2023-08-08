import path from "path"
import { defineConfig } from "vite"

import dts from "vite-plugin-dts"

module.exports = defineConfig({
  plugins: [
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
      external: ["react", "react-dom", "playbook-ui", "react/jsx-runtime"],
    },
  },
})
