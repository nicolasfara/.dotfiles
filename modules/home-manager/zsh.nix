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
      '';
    };

    # ------------------------------
    # Starship prompt configuration
    # ------------------------------
    starship = {
      enable = true;
      settings = {
        format = "$username$hostname$directory$git_branch$git_status$cmd_duration$line_break$character";
        
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
        
        git_branch = {
          style = "bold purple";
          format = "[$symbol$branch]($style) ";
        };
        
        git_status = {
          style = "bold yellow";
          conflicted = "🏳";
          ahead = "⇡";
          behind = "⇣";
          diverged = "⇕";
          untracked = "?";
          stashed = "$";
          modified = "!";
          staged = "+";
          renamed = "»";
          deleted = "✘";
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
      options = [ "--cmd" "cd" ];
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
