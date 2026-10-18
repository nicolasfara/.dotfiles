{ pkgs, ... }:

let
  # Konnect: MCP server exposing KiCad 10 schematic/PCB tooling to Claude and
  # other AI clients. Not in nixpkgs, so the prebuilt Linux binaries from the
  # KiCad PCM release zip are patchelf'd against nixpkgs libs. The PCM zip is
  # used over the standalone tarball because it also ships schematic-viewer
  # (a Tauri/WebKitGTK app launched by the `open_schematic_viewer` tool).
  #
  # Only the binaries are installed; the KiCad "External Plugins" button (a thin
  # Python launcher) is skipped since the MCP client spawns konnect over stdio.
  konnect = pkgs.stdenv.mkDerivation rec {
    pname = "konnect";
    version = "0.13.0";

    src = pkgs.fetchurl {
      url = "https://github.com/mixelpixx/Konnect/releases/download/v${version}/konnect-pcm-v${version}-linux.zip";
      hash = "sha256-JM9gA9KGBFKMtAsx3ikTeH2xW7+o0R/lfF5QcNdS0RM=";
    };

    nativeBuildInputs = with pkgs; [ unzip autoPatchelfHook wrapGAppsHook3 ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      cairo
      dbus
      gdk-pixbuf
      glib
      gtk3
      libsoup_3
      webkitgtk_4_1
    ];

    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 plugins/bin/konnect $out/bin/konnect
      install -Dm755 plugins/bin/schematic-viewer $out/bin/schematic-viewer
      runHook postInstall
    '';

    # Only the GTK viewer needs the GApps wrapper; wrapping konnect would just
    # add env noise to an stdio MCP server.
    dontWrapGApps = true;
    postFixup = ''
      wrapGApp $out/bin/schematic-viewer
    '';

    meta = with pkgs.lib; {
      description = "AI-assisted PCB design for KiCad 10 via the Model Context Protocol";
      homepage = "https://github.com/mixelpixx/Konnect";
      license = licenses.agpl3Only;
      platforms = [ "x86_64-linux" ];
      mainProgram = "konnect";
    };
  };
in
{
  home.packages = [ konnect ];

  # Konnect's auto-detection only probes FHS/flatpak/snap paths, so point it at
  # the nixpkgs KiCad explicitly (same `pkgs.kicad` installed in home.nix).
  xdg.configFile."konnect/config.toml".source =
    (pkgs.formats.toml { }).generate "konnect-config.toml" {
      kicad_cli = "${pkgs.kicad}/bin/kicad-cli";
      kicad_binary = "${pkgs.kicad}/bin/kicad";
    };
}
