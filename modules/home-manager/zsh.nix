{ ... }:

{
  programs = {
    zsh = {
      enable = true;
      syntaxHighlighting.enable = true;

      oh-my-zsh = {
        enable = true;
        theme = "af-magic";
        plugins = [
          "1password"
          "docker"
          "fasd"
          "fzf"
          "git"
          "rust"
          "sudo"
        ];
      };

      autosuggestion = {
        enable = true;
      };
      enableCompletion = true;
      # plugins = [
      #   {
      #     name = "powerlevel10k";
      #     src = pkgs.zsh-powerlevel10k;
      #     file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      #   }
      # ];
      # initContent = ''
      #   source ~/.p10k.zsh
      # '';
    };
  };
}
