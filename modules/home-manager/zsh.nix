{ ... }:

{
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;

      oh-my-zsh = {
        enable = true;
        theme = "";
        plugins = [
          "1password"
          "colored-man-pages"
          "command-not-found"
          "direnv"
          "docker"
          # "fasd"
          "fzf"
          "git"
          "rust"
          "sudo"
          "systemd"
        ];
      };

      initContent = ''
        DISABLE_AUTO_UPDATE=true
        DISABLE_UPDATE_PROMPT=true

        # Caching for completions
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path ~/.zsh/cache

        # The modern `nix shell` does not set IN_NIX_SHELL, which Starship uses
        # to display its nix_shell module. Add the marker only when starting an
        # interactive shell, leaving all other Nix commands untouched.
        nix() {
          if [[ "$1" != "shell" ]]; then
            command nix "$@"
            return
          fi

          local arg
          for arg in "$@"; do
            case "$arg" in
              --command|-c)
                command nix "$@"
                return
                ;;
            esac
          done

          command nix "$@" --command env IN_NIX_SHELL=impure "$SHELL"
        }
      '';
    };

    # ------------------------------
    # Starship prompt configuration
    # ------------------------------
    starship = {
      enable = true;
      settings = {
        format = "$username$hostname$directory$nix_shell$git_branch$git_status$cmd_duration$line_break$character";

        # Breeze colors
        palette = "breeze";

        palettes.breeze = {
          blue = "#3daee9";
          green = "#1cdc9a";
          purple = "#8e44ad";
          red = "#ed1515";
          yellow = "#fdbc4b";
        };

        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };

        directory = {
          style = "bold blue";
          truncation_length = 3;
          truncate_to_repo = true;
        };

        nix_shell = {
          format = "via [$symbol$state]($style) ";
          symbol = "❄ ";
          style = "bold blue";
        };

        git_branch = {
          style = "bold purple";
          format = "[$symbol$branch]($style) ";
        };

        git_status = {
          format = "([$all_status$ahead_behind]($style) )";
          style = "bold yellow";
        };

        cmd_duration = {
          min_time = 500;
          format = "[$duration]($style) ";
          style = "yellow";
        };
      };
    };

    # ------------------------------
    # Zoxide configuration
    # ------------------------------
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--cmd"
        "cd"
      ];
    };

    # ------------------------------
    # Direnv configuration
    # ------------------------------
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    # ------------------------------
    # Bat configuration
    # ------------------------------
    bat = {
      enable = true;
      config = {
        theme = "base16";
        style = "numbers,changes,header";
      };
    };
  };
}
