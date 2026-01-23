{ cmd, lib }:

rec {
  # Build commands (dev mode)
  build = { wasm-pack, path ? "." }:
    let
      wasmPackBin = lib.getExe wasm-pack;
    in {
      commands = {
        "wasm:build:web" = cmd "Build Wasm for web target" ''
          ${wasmPackBin} build ${path} --dev --target=web "$@"
        '';

        "wasm:build:nodejs" = cmd "Build Wasm for Node.js target" ''
          ${wasmPackBin} build ${path} --dev --target=nodejs "$@"
        '';

        "wasm:build:bundler" = cmd "Build Wasm for bundler target" ''
          ${wasmPackBin} build ${path} --dev --target=bundler "$@"
        '';
      };

      packages = [ wasm-pack ];
    };

  # Release commands
  release = { wasm-pack, path ? ".", gzip ? null }:
    let
      wasmPackBin = lib.getExe wasm-pack;
      gzipBin = if gzip != null then lib.getExe gzip else null;
      compress = if gzip != null then " && ${gzipBin} -f ${path}/pkg/*_bg.wasm" else "";
    in {
      commands = {
        "wasm:release:web" = cmd "Build Wasm release for web target" ''
          ${wasmPackBin} build ${path} --release --target=web "$@"${compress}
        '';

        "wasm:release:nodejs" = cmd "Build Wasm release for Node.js target" ''
          ${wasmPackBin} build ${path} --release --target=nodejs "$@"${compress}
        '';

        "wasm:release:bundler" = cmd "Build Wasm release for bundler target" ''
          ${wasmPackBin} build ${path} --release --target=bundler "$@"${compress}
        '';
      };

      packages =
        [ wasm-pack ] ++ (if gzip != null then [ gzip ] else []);
    };

  # Test commands
  test = { wasm-pack, path ? ".", features ? null }:
    let
      wasmPackBin = lib.getExe wasm-pack;
      featuresFlag = if features != null then " --features='${features}'" else "";
    in {
      commands = {
        "wasm:test:node" = cmd "Run wasm-pack tests in Node.js" ''
          ${wasmPackBin} test --node ${path}${featuresFlag} "$@"
        '';

        "wasm:test:chrome" = cmd "Run wasm-pack tests in headless Chrome" ''
          ${wasmPackBin} test --headless --chrome ${path}${featuresFlag} "$@"
        '';

        "wasm:test:firefox" = cmd "Run wasm-pack tests in headless Firefox" ''
          ${wasmPackBin} test --headless --firefox ${path}${featuresFlag} "$@"
        '';

        "wasm:test:safari" = cmd "Run wasm-pack tests in headless Safari" ''
          ${wasmPackBin} test --headless --safari ${path}${featuresFlag} "$@"
        '';
      };

      packages = [ wasm-pack ];
    };

  # Documentation commands
  doc = { cargo, xdg-open ? null }:
    let
      cargoBin = lib.getExe cargo;
      xdgOpenBin = if xdg-open != null then lib.getExe xdg-open else null;
    in {
      commands = {
        "wasm:doc" = cmd "Build docs for wasm32-unknown-unknown" ''
          ${cargoBin} doc --target=wasm32-unknown-unknown "$@"
        '';
      } // (if xdg-open != null then {
        "wasm:doc:open" = cmd "Build and open Wasm docs" ''
          ${cargoBin} doc --target=wasm32-unknown-unknown --open "$@"
        '';
      } else {});

      packages =
        if xdg-open != null then [ xdg-open ] else [];
    };

  # Watch commands
  watch = { cargo-watch }:
    let
      cargoWatchBin = lib.getExe cargo-watch;
    in {
      commands = {
        "wasm:watch:build" = cmd "Rebuild Wasm on changes" ''
          ${cargoWatchBin} --clear -- cargo build --target=wasm32-unknown-unknown
        '';

        "wasm:watch:test" = cmd "Run Wasm tests on changes" ''
          ${cargoWatchBin} --clear -x "test --target=wasm32-unknown-unknown"
        '';
      };

      packages = [ cargo-watch ];
    };

  # CI workflow
  ci = { wasm-pack, path ? ".", features ? null }:
    let
      wasmPackBin = lib.getExe wasm-pack;
      featuresFlag = if features != null then " --features='${features}'" else "";
    in {
      commands = {
        "wasm:ci" = cmd "Run Wasm CI suite (test node + chrome)" ''
          set -e
          echo "Running wasm-pack tests in Node.js..."
          ${wasmPackBin} test --node ${path}${featuresFlag}
          echo "Running wasm-pack tests in Chrome..."
          ${wasmPackBin} test --headless --chrome ${path}${featuresFlag}
          echo "Wasm CI passed!"
        '';
      };

      packages = [ wasm-pack ];
    };

  # Convenience: all wasm commands
  all = { wasm-pack, cargo, path ? ".", gzip ? null, features ? null, cargo-watch ? null, xdg-open ? null }:
    let
      modules = [
        (build { inherit wasm-pack path; })
        (ci { inherit wasm-pack path features; })
        (doc { inherit cargo xdg-open; })
        (release { inherit wasm-pack path gzip; })
        (test { inherit wasm-pack path features; })
      ]
      ++ (if cargo-watch != null then [ (watch { inherit cargo-watch; }) ] else []);
    in
      {
        commands = builtins.foldl' (acc: m: acc // m.commands) {} modules;
        packages = builtins.concatLists (map (m: m.packages) modules);
      };
}
