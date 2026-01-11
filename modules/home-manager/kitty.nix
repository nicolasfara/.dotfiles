{ ... }:

{
  programs = {
    kitty = {
      enable = true;
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 11;
      };
      
      settings = {
        # Tema Breeze Dark
        foreground = "#eff0f1";
        background = "#232629";
        
        cursor = "#eff0f1";
        cursor_text_color = "#232629";
        
        selection_foreground = "#232629";
        selection_background = "#3daee9";
        
        # Colori normali
        color0 = "#232629";
        color1 = "#ed1515";
        color2 = "#11d116";
        color3 = "#f67400";
        color4 = "#1d99f3";
        color5 = "#9b59b6";
        color6 = "#1abc9c";
        color7 = "#eff0f1";
        
        # Colori brillanti
        color8 = "#7f8c8d";
        color9 = "#c0392b";
        color10 = "#1cdc9a";
        color11 = "#fdbc4b";
        color12 = "#3daee9";
        color13 = "#8e44ad";
        color14 = "#16a085";
        color15 = "#fcfcfc";
        
        # Essenziali
        enable_audio_bell = "no";
        confirm_os_window_close = 0;
        update_check_interval = 0;
      };
      
      keybindings = {
        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";
      };
    };
  };
}