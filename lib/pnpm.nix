{ cmd }:

rec {
  # Install commands
  install = { pnpm }:
    {
      commands = {
        "pnpm:install" = cmd "Install dependencies" ''
          ${pnpm} install "$@"
        '';

        "pnpm:install:frozen" = cmd "Install with frozen lockfile" ''
          ${pnpm} install --frozen-lockfile
        '';
      };

      packages = [];
    };

  # Build commands
  build = { pnpm }:
    {
      commands = {
        "pnpm:build" = cmd "Build the project" ''
          ${pnpm} build "$@"
        '';

        "pnpm:build:watch" = cmd "Build in watch mode" ''
          ${pnpm} build --watch
        '';
      };

      packages = [];
    };

  # Development server
  dev = { pnpm }:
    {
      commands = {
        "pnpm:dev" = cmd "Start development server" ''
          ${pnpm} dev "$@"
        '';
      };

      packages = [];
    };

  # Test commands
  test = { pnpm }:
    {
      commands = {
        "pnpm:test" = cmd "Run tests" ''
          ${pnpm} test "$@"
        '';

        "pnpm:test:watch" = cmd "Run tests in watch mode" ''
          ${pnpm} test --watch
        '';

        "pnpm:test:coverage" = cmd "Run tests with coverage" ''
          ${pnpm} test --coverage "$@"
        '';
      };

      packages = [];
    };

  # Linting commands (eslint)
  lint = { pnpm }:
    {
      commands = {
        "pnpm:lint" = cmd "Run ESLint" ''
          ${pnpm} lint "$@"
        '';

        "pnpm:lint:fix" = cmd "Auto-fix ESLint issues" ''
          ${pnpm} lint --fix "$@"
        '';
      };

      packages = [];
    };

  # Formatting commands (prettier)
  fmt = { pnpm }:
    {
      commands = {
        "pnpm:fmt" = cmd "Format code with Prettier" ''
          ${pnpm} format "$@"
        '';

        "pnpm:fmt:check" = cmd "Check code formatting" ''
          ${pnpm} format --check "$@"
        '';
      };

      packages = [];
    };

  # TypeScript
  typecheck = { pnpm }:
    {
      commands = {
        "pnpm:typecheck" = cmd "Run TypeScript type checking" ''
          ${pnpm} typecheck "$@"
        '';

        "pnpm:typecheck:watch" = cmd "Type check in watch mode" ''
          ${pnpm} typecheck --watch
        '';
      };

      packages = [];
    };

  # CI workflow
  ci = { pnpm }:
    {
      commands = {
        "pnpm:ci" = cmd "Run full CI suite (install, lint, typecheck, test, build)" ''
          set -e
          echo "Installing dependencies..."
          ${pnpm} install --frozen-lockfile
          echo "Running linter..."
          ${pnpm} lint
          echo "Running type checker..."
          ${pnpm} typecheck
          echo "Running tests..."
          ${pnpm} test
          echo "Building..."
          ${pnpm} build
          echo "CI passed!"
        '';
      };

      packages = [];
    };

  # Convenience: all standard commands
  all = { pnpm }:
    let
      modules = [
        (build { inherit pnpm; })
        (ci { inherit pnpm; })
        (dev { inherit pnpm; })
        (fmt { inherit pnpm; })
        (install { inherit pnpm; })
        (lint { inherit pnpm; })
        (test { inherit pnpm; })
        (typecheck { inherit pnpm; })
      ];
    in
      {
        commands = builtins.foldl' (acc: m: acc // m.commands) {} modules;
        packages = builtins.concatLists (map (m: m.packages) modules);
      };
}
