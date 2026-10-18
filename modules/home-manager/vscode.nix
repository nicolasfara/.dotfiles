{ pkgs, ... }:
let
  inherit (pkgs.nix4vscode) forVscode;

  # nixpkgs' cpptools 1.34 leaves the new bin/cpptools-srv2 non-executable and with a
  # relative `./libc.so` interpreter. At activation the extension tries to chmod it,
  # hits EROFS in the store and fails, which leaves PlatformIO (that depends on it)
  # stuck at "Initializing PlatformIO Core". Treat it like its cpptools-srv sibling.
  cpptools = pkgs.vscode-extensions.ms-vscode.cpptools.overrideAttrs (old: {
    postPatch = old.postPatch + ''
      chmod +x bin/cpptools-srv2
    '';
    postFixup =
      old.postFixup
      + pkgs.lib.optionalString (pkgs.stdenv.hostPlatform.system == "x86_64-linux") ''
        patchelf --set-interpreter $out/share/vscode/extensions/ms-vscode.cpptools/bin/libc.so $out/share/vscode/extensions/ms-vscode.cpptools/bin/cpptools-srv2
      '';
  });

  # With useBuiltinPIOCore off, the extension looks for a `python3` in customPATH that
  # can `import platformio` (the `pio` binary alone isn't enough), so expose
  # platformio-core as a module of its own interpreter.
  pioPython = pkgs.platformio-core.python.withPackages (ps: [
    (ps.toPythonModule pkgs.platformio-core)
  ]);
in
{
  programs.vscode = {
      enable = true;
      mutableExtensionsDir = false;

      profiles.default.extensions = forVscode [
        "james-yu.latex-workshop"
        "rust-lang.rust-analyzer"
        "jnoortheen.nix-ide"
        "myriad-dreamin.tinymist"
        "scalameta.metals"
        "scala-lang.scala"
        "mkhl.direnv"
        "github.vscode-github-actions"
        "github.copilot-chat"
        "astro-build.astro-vscode"
        "tamasfe.even-better-toml"
        "anthropic.claude-code"
        # pinned like your old marketplace entry
        "openai.chatgpt"
        "ms-vscode-remote.vscode-remote-extensionpack"
        "ms-vscode-remote.remote-ssh"
      ] ++ [
        # PlatformIO hard-depends on cpptools, which VS Code can't auto-install into
        # the immutable extensions dir. Taken from nixpkgs (not nix4vscode) because
        # nixpkgs patches its bundled native binaries to run on NixOS.
        cpptools
        pkgs.vscode-extensions.platformio.platformio-vscode-ide
      ];

      profiles.default.userSettings = {
        "terminal.integrated.mouseWheelScrollSensitivity" = 3;
        "terminal.integrated.gpuAcceleration" = "off";
        "claudeCode.preferredLocation" = "panel";
        "remote.SSH.useExecServer" = false;

        # Out of the box the extension bootstraps its own Python + PlatformIO Core
        # into ~/.platformio/penv, which breaks on NixOS. Point it at nixpkgs' core
        # instead; the toolchains it downloads into ~/.platformio/packages run via
        # nix-ld (see nixos/dev-boards.nix).
        "platformio-ide.useBuiltinPIOCore" = false;
        "platformio-ide.useBuiltinPython" = false;
        "platformio-ide.customPATH" = "${pioPython}/bin";
      };
    };
}
