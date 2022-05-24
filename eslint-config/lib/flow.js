module.exports = {
  extends: [
    "@powerhome/eslint-config/base",
    "plugin:flowtype/recommended"
  ],
  plugins: ["flowtype"],
  ignorePatterns: ["flow-typed/**/*"],
}
