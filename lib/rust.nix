{ cmd, lib }:

rec {
  # Testing commands
  test = { cargo, cargo-watch ? null }:
    let
      cargoBin = lib.getExe cargo;
      cargoWatchBin = if cargo-watch != null then lib.getExe cargo-watch else null;
    in {
      commands = {
        "rust:test" = cmd "Run all tests" ''
          ${cargoBin} test "$@"
        '';

        "rust:test:doc" = cmd "Run documentation tests" ''
          ${cargoBin} test --doc "$@"
        '';
      } // (if cargo-watch != null then {
        "rust:test:watch" = cmd "Run tests in watch mode" ''
          ${cargoWatchBin} --clear -x "test $*"
        '';
      } else {});

      packages =
        if cargo-watch != null then [ cargo-watch ] else [];
    };

  # Benchmarking commands
  bench = { cargo, cargo-criterion ? null, xdg-open ? null }:
    let
      cargoBin = lib.getExe cargo;
      cargoCriterionBin = if cargo-criterion != null then lib.getExe cargo-criterion else null;
      xdgOpenBin = if xdg-open != null then lib.getExe xdg-open else null;
    in {
      commands = {
        "rust:bench" = cmd "Run benchmarks" ''
          ${cargoBin} bench "$@"
        '';
      } // (if cargo-criterion != null then {
        "rust:bench:criterion" = cmd "Run Criterion benchmarks" ''
          ${cargoCriterionBin} "$@"
        '';
      } else {})
      // (if xdg-open != null then {
        "rust:bench:open" = cmd "Open benchmark report in browser" ''
          ${xdgOpenBin} ./target/criterion/report/index.html
        '';
      } else {});

      packages =
        (if cargo-criterion != null then [ cargo-criterion ] else [])
        ++ (if xdg-open != null then [ xdg-open ] else []);
    };

  # Linting commands
  lint = { cargo }:
    let
      cargoBin = lib.getExe cargo;
    in {
      commands = {
        "rust:clippy" = cmd "Run Clippy lints" ''
          ${cargoBin} clippy --all-targets --all-features "$@"
        '';

        "rust:clippy:pedantic" = cmd "Run Clippy with pedantic lints" ''
          ${cargoBin} clippy --all-targets --all-features -- -W clippy::pedantic -W clippy::nursery "$@"
        '';

        "rust:clippy:fix" = cmd "Auto-fix Clippy warnings" ''
          ${cargoBin} clippy --fix --allow-dirty --allow-staged "$@"
        '';
      };

      packages = [];
    };

  # Formatting commands
  fmt = { cargo }:
    let
      cargoBin = lib.getExe cargo;
    in {
      commands = {
        "rust:fmt" = cmd "Format code" ''
          ${cargoBin} fmt --all "$@"
        '';

        "rust:fmt:check" = cmd "Check code formatting" ''
          ${cargoBin} fmt --all -- --check
        '';
      };

      packages = [];
    };

  # Build commands
  build = { cargo }:
    let
      cargoBin = lib.getExe cargo;
    in {
      commands = {
        "rust:build" = cmd "Build the project" ''
          ${cargoBin} build "$@"
        '';

        "rust:build:release" = cmd "Build in release mode" ''
          ${cargoBin} build --release "$@"
        '';

        "rust:check" = cmd "Check the project compiles" ''
          ${cargoBin} check --all-targets --all-features "$@"
        '';
      };

      packages = [];
    };

  # Documentation commands
  doc = { cargo }:
    let
      cargoBin = lib.getExe cargo;
    in {
      commands = {
        "rust:doc" = cmd "Build documentation" ''
          ${cargoBin} doc --no-deps "$@"
        '';

        "rust:doc:open" = cmd "Build and open documentation" ''
          ${cargoBin} doc --no-deps --open "$@"
        '';

        "rust:doc:check" = cmd "Check docs build without warnings" ''
          RUSTDOCFLAGS="-D warnings" ${cargoBin} doc --no-deps --all-features "$@"
        '';
      };

      packages = [];
    };

  # Watch mode commands
  watch = { cargo-watch }:
    let
      cargoWatchBin = lib.getExe cargo-watch;
    in {
      commands = {
        "rust:watch:build" = cmd "Rebuild on changes" ''
          ${cargoWatchBin} --clear
        '';

        "rust:watch:clippy" = cmd "Run Clippy on changes" ''
          ${cargoWatchBin} --clear -x clippy
        '';

        "rust:watch:test" = cmd "Run tests on changes" ''
          ${cargoWatchBin} --clear -x test
        '';
      };

      packages = [ cargo-watch ];
    };

  # Security and compatibility commands
  audit = { cargo-audit }:
    let
      cargoAuditBin = lib.getExe cargo-audit;
    in {
      commands = {
        "rust:audit" = cmd "Scan for security vulnerabilities" ''
          ${cargoAuditBin} audit "$@"
        '';
      };

      packages = [ cargo-audit ];
    };

  semver = { cargo-semver-checks }:
    let
      cargoSemverChecksBin = lib.getExe cargo-semver-checks;
    in {
      commands = {
        "rust:semver" = cmd "Check API compatibility for libraries" ''
          ${cargoSemverChecksBin} semver-checks check-release "$@"
        '';
      };

      packages = [ cargo-semver-checks ];
    };

  msrv = { cargo, cargo-msrv ? null }:
    let
      cargoBin = lib.getExe cargo;
      cargoMsrvBin = if cargo-msrv != null then lib.getExe cargo-msrv else null;
    in {
      commands = {
        "rust:msrv:verify" = cmd "Verify MSRV from Cargo.toml" ''
          ${cargoBin} check --all-targets --all-features "$@"
        '';
      } // (if cargo-msrv != null then {
        "rust:msrv:find" = cmd "Find minimum supported Rust version" ''
          ${cargoMsrvBin} find "$@"
        '';
      } else {});

      packages =
        if cargo-msrv != null then [ cargo-msrv ] else [];
    };

  # CI workflow
  ci = { cargo }:
    let
      cargoBin = lib.getExe cargo;
    in {
      commands = {
        "rust:ci" = cmd "Run full CI suite (fmt, clippy, test)" ''
          set -e
          echo "Checking formatting..."
          ${cargoBin} fmt --all -- --check
          echo "Running Clippy..."
          ${cargoBin} clippy --all-targets --all-features -- -D warnings
          echo "Running Clippy (pedantic)..."
          ${cargoBin} clippy --all-targets --all-features -- -W clippy::pedantic -W clippy::nursery
          echo "Running tests..."
          ${cargoBin} test --all-features
          echo "Checking docs..."
          RUSTDOCFLAGS="-D warnings" ${cargoBin} doc --no-deps --all-features
          echo "Building release..."
          ${cargoBin} build --release
          echo "CI passed!"
        '';
      };

      packages = [];
    };

  # Convenience: all standard commands
  all = {
    cargo,
    cargo-audit ? null,
    cargo-criterion ? null,
    cargo-msrv ? null,
    cargo-semver-checks ? null,
    cargo-watch ? null,
    xdg-open ? null
  }:
    let
      modules = [
        (test { inherit cargo cargo-watch; })
        (bench { inherit cargo cargo-criterion xdg-open; })
        (lint { inherit cargo; })
        (fmt { inherit cargo; })
        (build { inherit cargo; })
        (doc { inherit cargo; })
        (ci { inherit cargo; })
        (msrv { inherit cargo cargo-msrv; })
      ]
      ++ (if cargo-audit != null then [ (audit { inherit cargo-audit; }) ] else [])
      ++ (if cargo-semver-checks != null then [ (semver { inherit cargo-semver-checks; }) ] else [])
      ++ (if cargo-watch != null then [ (watch { inherit cargo-watch; }) ] else []);
    in
      {
        commands = builtins.foldl' (acc: m: acc // m.commands) {} modules;
        packages = builtins.concatLists (map (m: m.packages) modules);
      };
}
