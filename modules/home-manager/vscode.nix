{ pkgs, ... }:
let
  inherit (pkgs.nix4vscode) forVscode forOpenVsx;
in
{
  programs.vscode =
    let
      inherit (pkgs.nix4vscode) forVscode;
    in
    {
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

        # pinned like your old marketplace entry
        "openai.chatgpt.0.4.79"
      ];
    };
}