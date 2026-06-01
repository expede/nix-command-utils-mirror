# Nix Command Utils

Helpers for defining commands for Nix shells under Flakes.

## Quickstart

``` nix
{
  inputs = {
    command-utils.url = "git+https://codeberg.org/expede/nix-command-utils";
    flake-utils.url = "github:numtide/flake-utils";
    # ...
  };

  outputs = {self, flake-utils, command-utils}:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Cargo just for example
        cargo = "${pkgs.cargo}/bin/cargo";

        cmd = command-utils.cmd.${system};
        asModule = command-utils.asModule.${system};

        menu = command-utils.commands.${system} [
          (asModule {
            hello = cmd "Print a hello world message" "echo 'Hello, world!'";

            "project:build" = cmd "Build the project"
              "${cargo} build";

            "project:test" = cmd "Run tests"
              "${cargo} test";
          })
        ];
        #...
      in
        devShells.default = pkgs.mkShell {
          packages = menu;  # Includes menu script + command wrappers
        };
      }
    );
}
```

``` console
$ menu
  ____                                          _
 / ___|___  _ __ ___  _ __ ___   __ _ _ __   __| |___
| |   / _ \| '_ ` _ \| '_ ` _ \ / _` | '_ \ / _` / __|
| |__| (_) | | | | | | | | | | | (_| | | | | (_| \__ \
 \____\___/|_| |_| |_|_| |_| |_|\__,_|_| |_|\__,_|___/

┌───────────────┬───────────────────────────────┐
│ Command       │ Description                   │
╞═══════════════╪═══════════════════════════════╡
│ hello         │ Print a hello world message   │
├───────────────┼───────────────────────────────┤
│ project:build │ Build the project             │
├───────────────┼───────────────────────────────┤
│ project:test  │ Run tests                     │
└───────────────┴───────────────────────────────┘

$ hello
⚙️  Running hello...
Hello, world!
```

## Adding Help Text

Use `withHelp` to add detailed help text accessible via `--help` or `-h`:

``` nix
menu = command-utils.commands.${system} [
  (asModule {
    hello = cmd "Print a hello world message" "echo 'Hello, world!'";

    "rust:bench" = withHelp ''
      Usage: rust:bench [OPTIONS]

      Options:
        --release    Run in release mode
        --save FILE  Save results to FILE

      Examples:
        rust:bench --release
        rust:bench --save baseline.json
    '' (cmd "Run benchmarks" "${cargo} bench");
  })
];
```

``` console
$ rust:bench --help
rust:bench - Run benchmarks

Usage: rust:bench [OPTIONS]

Options:
  --release    Run in release mode
  --save FILE  Save results to FILE

Examples:
  rust:bench --release
  rust:bench --save baseline.json
```

Commands without `withHelp` pass `--help` through to the underlying script.

## Rust Commands

Pre-built command sets for Rust development, organized by module:

| Module        | Commands                                                   |
|---------------|:-----------------------------------------------------------|
| `rust.test`   | `rust:test`, `rust:test:doc`, `rust:test:watch`            |
| `rust.bench`  | `rust:bench`, `rust:bench:criterion`, `rust:bench:open`    |
| `rust.lint`   | `rust:clippy`, `rust:clippy:pedantic`, `rust:clippy:fix`   |
| `rust.fmt`    | `rust:fmt`, `rust:fmt:check`                               |
| `rust.build`  | `rust:build`, `rust:build:release`, `rust:check`           |
| `rust.doc`    | `rust:doc`, `rust:doc:open`, `rust:doc:check`              |
| `rust.watch`  | `rust:watch:build`, `rust:watch:clippy`, `rust:watch:test` |
| `rust.audit`  | `rust:audit`                                               |
| `rust.semver` | `rust:semver`                                              |
| `rust.msrv`   | `rust:msrv:verify`, `rust:msrv:find`                       |
| `rust.ci`     | `rust:ci` (fmt, clippy, test, doc, release build)          |
| `rust.all`    | All of the above                                           |

### Importing Specific Modules

``` nix
let
  cargo = rust-toolchain;
  cargo-watch = pkgs.cargo-watch;

  rust = command-utils.rust.${system};
  asModule = command-utils.asModule.${system};

  menu = command-utils.commands.${system} [
    # Pick only what you need
    (rust.test { inherit cargo cargo-watch; })
    (rust.lint { inherit cargo; })
    (rust.fmt { inherit cargo; })
    # Add your own commands
    (asModule {
      hello = cmd "Say hello" "echo 'Hello!'";
    })
  ];
in
  pkgs.mkShell {
    # Includes menu, command wrappers, AND cargo-watch
    packages = menu;
  }
```

### Importing All Rust Commands

``` nix
let
  cargo = rust-toolchain;
  cargo-audit = pkgs.cargo-audit;
  cargo-criterion = pkgs.cargo-criterion;
  cargo-msrv = pkgs.cargo-msrv;
  cargo-semver-checks = pkgs.cargo-semver-checks;
  cargo-watch = pkgs.cargo-watch;
  xdg-open = pkgs.xdg-utils;

  rust = command-utils.rust.${system};
  asModule = command-utils.asModule.${system};
  cmd = command-utils.cmd.${system};

  menu = command-utils.commands.${system} [
    (rust.all {
      inherit cargo cargo-audit cargo-criterion cargo-msrv cargo-semver-checks cargo-watch xdg-open;
    })
    # Add project-specific commands
    (asModule {
      "db:migrate" = cmd "Run database migrations" "cargo run --bin migrate";
    })
  ];
in
  pkgs.mkShell {
    # All tools are included automatically!
    packages = menu ++ [ rust-toolchain ];
  }
```

### Module Parameters

Each module takes a configuration attrset. All tool parameters expect **derivations** (e.g., `pkgs.cargo-watch`), not binary paths. The library uses `lib.getExe` internally to extract the binary path. Optional tools enable additional commands:

| Module        | Required              | Optional                                                                                         |
|---------------|:----------------------|:-------------------------------------------------------------------------------------------------|
| `rust.test`   | `cargo`               | `cargo-watch` → `rust:test:watch`                                                                |
| `rust.bench`  | `cargo`               | `cargo-criterion` → `rust:bench:criterion`, `xdg-open` → `rust:bench:open`                       |
| `rust.lint`   | `cargo`               | —                                                                                                |
| `rust.fmt`    | `cargo`               | —                                                                                                |
| `rust.build`  | `cargo`               | —                                                                                                |
| `rust.doc`    | `cargo`               | —                                                                                                |
| `rust.watch`  | `cargo-watch`         | —                                                                                                |
| `rust.audit`  | `cargo-audit`         | —                                                                                                |
| `rust.semver` | `cargo-semver-checks` | —                                                                                                |
| `rust.msrv`   | `cargo`               | `cargo-msrv` → `rust:msrv:find`                                                                  |
| `rust.ci`     | `cargo`               | —                                                                                                |
| `rust.all`    | `cargo`               | `cargo-audit`, `cargo-criterion`, `cargo-msrv`, `cargo-semver-checks`, `cargo-watch`, `xdg-open` |

## pnpm Commands

Pre-built command sets for JavaScript/TypeScript development with pnpm:

| Module           | Commands                                             |
|------------------|:-----------------------------------------------------|
| `pnpm.install`   | `pnpm:install`, `pnpm:install:frozen`                |
| `pnpm.build`     | `pnpm:build`, `pnpm:build:watch`                     |
| `pnpm.dev`       | `pnpm:dev`                                           |
| `pnpm.test`      | `pnpm:test`, `pnpm:test:watch`, `pnpm:test:coverage` |
| `pnpm.lint`      | `pnpm:lint`, `pnpm:lint:fix`                         |
| `pnpm.fmt`       | `pnpm:fmt`, `pnpm:fmt:check`                         |
| `pnpm.typecheck` | `pnpm:typecheck`, `pnpm:typecheck:watch`             |
| `pnpm.ci`        | `pnpm:ci` (install, lint, typecheck, test, build)    |
| `pnpm.all`       | All of the above                                     |

### Importing Specific Modules

``` nix
let
  pnpm' = "${pkgs.pnpm}/bin/pnpm";

  pnpm = command-utils.pnpm.${system};

  menu = command-utils.commands.${system} [
    (pnpm.install { pnpm = pnpm'; })
    (pnpm.test { pnpm = pnpm'; })
    (pnpm.lint { pnpm = pnpm'; })
  ];
in
  pkgs.mkShell {
    packages = menu;
  }
```

### Importing All pnpm Commands

``` nix
let
  pnpm' = "${pkgs.pnpm}/bin/pnpm";

  pnpm = command-utils.pnpm.${system};
  asModule = command-utils.asModule.${system};
  cmd = command-utils.cmd.${system};

  menu = command-utils.commands.${system} [
    (pnpm.all { pnpm = pnpm'; })
    # Add project-specific commands
    (asModule {
      storybook = cmd "Start Storybook" "${pnpm'} storybook";
    })
  ];
in
  pkgs.mkShell {
    packages = menu;
  }
```

### Module Parameters

All pnpm modules require only the `pnpm` executable path (note: pnpm still uses paths, not derivations).

## Wasm Commands

Pre-built command sets for wasm-pack and wasm-bindgen development:

| Module         | Commands                                                                      |
|----------------|:------------------------------------------------------------------------------|
| `wasm.build`   | `wasm:build:web`, `wasm:build:nodejs`, `wasm:build:bundler`                   |
| `wasm.release` | `wasm:release:web`, `wasm:release:nodejs`, `wasm:release:bundler`             |
| `wasm.test`    | `wasm:test:node`, `wasm:test:chrome`, `wasm:test:firefox`, `wasm:test:safari` |
| `wasm.doc`     | `wasm:doc`, `wasm:doc:open`                                                   |
| `wasm.watch`   | `wasm:watch:build`, `wasm:watch:test`                                         |
| `wasm.ci`      | `wasm:ci` (test node + chrome)                                                |
| `wasm.all`     | All of the above                                                              |

### Importing Wasm Commands

``` nix
let
  cargo = rust-toolchain;
  cargo-watch = pkgs.cargo-watch;
  gzip = pkgs.gzip;
  wasm-pack = pkgs.wasm-pack;

  wasm = command-utils.wasm.${system};

  menu = command-utils.commands.${system} [
    (wasm.build { inherit wasm-pack; })
    (wasm.release { inherit wasm-pack gzip; })
    (wasm.test { inherit wasm-pack; features = "browser_test"; })
  ];
in
  pkgs.mkShell {
    # wasm-pack, gzip, etc. included automatically
    packages = menu ++ [ rust-toolchain ];
  }
```

### Monorepo Support

For projects where Wasm lives in a subdirectory, use the `path` parameter:

``` nix
wasm.build { inherit wasm-pack; path = "./my_wasm_crate"; }
wasm.release { inherit wasm-pack gzip; path = "./my_wasm_crate"; }
wasm.test { inherit wasm-pack; path = "./my_wasm_crate"; }
```

### Module Parameters

All rust and wasm module parameters expect **derivations** (e.g., `pkgs.cargo-watch`), not binary paths. The library uses `lib.getExe` internally to extract the binary path.

| Module         | Required             | Optional                                              |
|----------------|:---------------------|:------------------------------------------------------|
| `wasm.build`   | `wasm-pack`          | `path` (default: `.`)                                 |
| `wasm.release` | `wasm-pack`          | `path`, `gzip` → compress output                      |
| `wasm.test`    | `wasm-pack`          | `path`, `features` → `--features` flag                |
| `wasm.doc`     | `cargo`              | `xdg-open` → `wasm:doc:open`                          |
| `wasm.watch`   | `cargo-watch`        | —                                                     |
| `wasm.ci`      | `wasm-pack`          | `path`, `features`                                    |
| `wasm.all`     | `wasm-pack`, `cargo` | `path`, `gzip`, `features`, `cargo-watch`, `xdg-open` |

## Project Structure

```
nix-command-utils/
├── flake.nix        # Main entry point
├── lib/
│   ├── core.nix     # cmd, withHelp, asModule, commands
│   ├── pnpm.nix     # pnpm command modules
│   ├── rust.nix     # Rust command modules
│   └── wasm.nix     # Wasm command modules
├── LICENSE
└── README.md
```
