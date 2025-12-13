{ pkgs, ... }:

let
  multimedia-deps = with pkgs; [
    ffmpeg
    mpv
    vlc
  ];
  graphics-deps = with pkgs; [
    gimp
    inkscape
  ];
  shell-deps = with pkgs; [
    btop
    cabextract
    coreutils-full
    file
    fasd
    fastfetch
    fzf
    gh
    git
    git-quick-stats
    gnumake
    httpie
    icu
    iperf
    iperf2
    ipmitool
    killall
    libyaml
    ncdu
    neofetch
    nil
    nmap
    ookla-speedtest
    p7zip
    pciutils
    podman
    rsync
    screen
    sshfs
    tmux
    tree
    unrar
    unzip
    walk
    watch
    wget
    wl-clipboard
    xclip
    zstd
  ];
  applications-deps = with pkgs; [
    discord
    freecad-wayland
    google-chrome
    jetbrains.idea-ultimate
    kicad
    onlyoffice-desktopeditors
    prusa-slicer
    remmina
    signal-desktop-bin
    spotify
    teams-for-linux
    telegram-desktop
    vesktop
    wireshark
    zoom-us
  ];
  programming-deps = with pkgs; [
    android-tools
    coursier
    eslint
    espup
    gcc
    gradle
    kotlin
    metals
    nodejs_24
    rustup
    ruby
    sbt
    scala
    scala-cli
    uv
    yarn
  ];
in {
  home.username = "nicolas";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
    prismlauncher
    k9s
    kubectl
    minikube
    nixfmt-rfc-style
    age
    typst
    typstyle
    texlive.combined.scheme-full
    fira-sans
    fira-math
    font-awesome
    mqttui
    kdePackages.kamoso    
  ] ++ multimedia-deps ++ graphics-deps ++ shell-deps ++ applications-deps ++ programming-deps;

  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".tmux.conf".text = ''
      # Smart pane switching with awareness of Vim splits.
      # See: https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l
    '';
  };

  home.sessionVariables = {
    EDITOR = "vim";
  };

  # Enable Nix experimental features for user
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  programs = {
    home-manager.enable = true;
    gpg.enable = true;
    google-chrome.enable = true;

    java = {
      enable = true;
      package = pkgs.jdk25;
    };
    vscode = {
      enable = true;
      mutableExtensionsDir = false;
      profiles.default.extensions = with pkgs.vscode-extensions; [
        james-yu.latex-workshop
        rust-lang.rust-analyzer
        jnoortheen.nix-ide
        myriad-dreamin.tinymist
        scalameta.metals
        scala-lang.scala
        mkhl.direnv
        github.vscode-github-actions
        github.copilot
        github.copilot-chat
      ];
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Nicolas Farabegoli";
        email = "nicolas.farabegoli@gmail.com";
      };
      pull = {
        rebase = true;
      };
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = if pkgs.stdenv.isLinux then pkgs.pinentry-all else pkgs.pinentry_mac;
  };
}
