module.exports = {
  extends: ["@powerhome/eslint-config/base"],
  overrides: [
    {
      files: ["**/*.ts", "**/*.tsx"],
      extends: ["plugin:@typescript-eslint/recommended"],
      parser: "@typescript-eslint/parser",
      plugins: ["@typescript-eslint"],
      rules: {
        "flowtype/no-types-missing-file-annotation": 0,
        "jsx-control-statements/jsx-use-if-tag": 0,
        "no-use-before-define": 0,
        "@typescript-eslint/no-array-constructor": 0,
        "@typescript-eslint/explicit-module-boundary-types": 0,
        "@typescript-eslint/no-var-requires": 0,
        "@typescript-eslint/no-unused-vars": 1,
        "@typescript-eslint/no-use-before-define": [
          2,
          { functions: true, classes: true },
        ],
      },
    },
  ],
}
