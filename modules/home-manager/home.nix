{ pkgs, ... }:

{
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
    gimp
    unzip
    unrar
    p7zip
    fzf
    wireshark
    libyaml
    ruby
    coreutils-full
    git-quick-stats
    gnumake
    inkscape
    gnumake
    wl-clipboard
    xclip
    tree
    zstd
    walk
    rsync
    watch
    tmux
    nmap
    ncdu

    pciutils
    tmux
    ipmitool
    teams-for-linux
    yarn
    screen
    killall
    file
    gh
    gcc
    fastfetch
    btop
    sshfs
    icu
    discord
    vesktop
    google-chrome
    spotify
    neofetch
    jetbrains.idea-ultimate
    signal-desktop-bin
    prismlauncher
    git
    ffmpeg
    k9s
    kubectl
    minikube
    zoom-us
    wget
    cabextract
    podman
    ookla-speedtest
    iperf
    iperf2

    nil

    telegram-desktop
    nixfmt-rfc-style

    age

    remmina

    kicad

    freecad-wayland
    prusa-slicer

    typst
    typstfmt

    texlive.combined.scheme-full

    fira-sans
    fira-math
    font-awesome

    nodejs_24
    eslint

    inkscape

    onlyoffice-desktopeditors

    mqttui
    uv

    kdePackages.kamoso

    android-tools

    # JVM
    gradle
    scala
    metals
    coursier
    sbt
    scala-cli
    kotlin

    rustup
    espup
  ];

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
      package = pkgs.jdk23;
    };
    vscode = {
      enable = true;
      profiles.default.extensions = with pkgs.vscode-extensions; [
        james-yu.latex-workshop
        rust-lang.rust-analyzer
        jnoortheen.nix-ide
        myriad-dreamin.tinymist
        scalameta.metals
      ];
    };
  };

  programs.git = {
    enable = true;
    userName = "Nicolas Farabegoli";
    userEmail = "nicolas.farabegoli@gmail.com";
    extraConfig = {
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
