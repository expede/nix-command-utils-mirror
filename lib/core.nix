{ pkgs }:

let
  inherit (pkgs.lib) escapeShellArg;

  cmd = description: script: { inherit description script; help = null; };

  withHelp = help: def: def // { inherit help; };

  # Wrap raw command definitions into module format
  asModule = cmds: { commands = cmds; packages = []; };

  command = { name, script, description ? "<No description given>", help ? null }:
    let
      helpHandler =
        if help != null then ''
          if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            echo ${escapeShellArg "${name} - ${description}"}
            echo ""
            echo ${escapeShellArg help}
            exit 0
          fi
        '' else "";
    in
      {
        inherit name description;

        package =
          pkgs.writeScriptBin name ''
          #!${pkgs.bash}/bin/bash
          ${helpHandler}
          echo ${escapeShellArg "⚙️  Running ${name}..."}
          ${script}
        '';
      };

  # Accepts a list of modules, each with { commands, packages }
  # Returns a flat list of packages: [ menu cmd-scripts... tool-packages... ]
  commands = modules:
    let
      # Merge all command definitions
      allCommands = builtins.foldl' (acc: m: acc // m.commands) {} modules;

      # Collect all tool packages
      toolPackages = builtins.concatLists (map (m: m.packages) modules);

      names = builtins.attrNames allCommands;
      defs = allCommands;

      helper =
        let
          # Calculate max widths
          cmdHeader = "Command";
          descHeader = "Description";

          nameLengths = map builtins.stringLength names;
          descLengths = map (n: builtins.stringLength (builtins.getAttr n defs).description) names;

          maxNameLen = builtins.foldl'
            (acc: x: if x > acc then x else acc)
            (builtins.stringLength cmdHeader)
            nameLengths;

          maxDescLen = builtins.foldl'
            (acc: x: if x > acc then x else acc)
            (builtins.stringLength descHeader)
            descLengths;

          # Generate padding strings
          repeat = char: count:
            let
              go = acc: n:
                if n <= 0
                then acc
                else go (acc + char) (n - 1);
            in
              go "" count;

          pad = str: width:
            let
              strLen = builtins.stringLength str;
              padLen = width - strLen;
            in
              str + repeat " " padLen;

          # Table components (double line only for header separator)
          hLineDouble = repeat "═";
          hLineSingle = repeat "─";

          topBorder    = "┌─${hLineSingle maxNameLen}─┬─${hLineSingle maxDescLen}─┐";
          headerSep    = "╞═${hLineDouble maxNameLen}═╪═${hLineDouble maxDescLen}═╡";
          rowDivider   = "├─${hLineSingle maxNameLen}─┼─${hLineSingle maxDescLen}─┤";
          bottomBorder = "└─${hLineSingle maxNameLen}─┴─${hLineSingle maxDescLen}─┘";
          headerRow    = "│ ${pad cmdHeader maxNameLen} │ ${pad descHeader maxDescLen} │";

          # Build data rows
          mkRow = name:
            let
              desc = (builtins.getAttr name defs).description;
            in
              "│ ${pad name maxNameLen} │ ${pad desc maxDescLen} │";

          dataRows = map mkRow names;

          # Interleave rows with dividers
          interleave = rows:
            if builtins.length rows <= 1
            then rows
            else [ (builtins.head rows) rowDivider ] ++ interleave (builtins.tail rows);

          # Combine all lines
          allLines = [ topBorder headerRow headerSep ] ++ interleave dataRows ++ [ bottomBorder ];
          echoLines = builtins.concatStringsSep " && " (map (l: "echo ${escapeShellArg l}") allLines);

        in
          pkgs.writeScriptBin "menu" ''
            #!${pkgs.stdenv.shell}
            ${pkgs.figlet}/bin/figlet "Commands" | ${pkgs.lolcat}/bin/lolcat
            echo ""
            ${echoLines}
          '';

      mapper = name:
        let
          element =
            builtins.getAttr name defs;

          task = command {
            inherit name;
            inherit (element) description script;
            help = element.help or null;
          };
        in
          task.package;

      commandPackages =
        map mapper names;

    in
      [ helper ] ++ commandPackages ++ toolPackages;

in
  { inherit cmd withHelp command commands asModule; }
