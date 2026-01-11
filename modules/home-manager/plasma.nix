{ ... }:
{
  programs = {
    plasma = {
      enable = true;
      
      panels = [
        {
          location = "bottom";
          widgets = [
            {
              kickoff = {
                sortAlphabetically = true;
                # icon = "nix-snowflake-white";
              };
            }
            {
              iconTasks = {
                launchers = [
                  "applications:org.kde.dolphin.desktop"
                  "applications:kitty.desktop"
                  # "applications:org.kde.konsole.desktop"
                  "applications:google-chrome.desktop"
                ];
              };
            }
            "org.kde.plasma.marginsseparator"
            "org.kde.plasma.systemmonitor.cpucore"
            {
              systemTray.items = {
                shown = [
                  "org.kde.plasma.battery"
                  "org.kde.plasma.bluetooth"
                  "org.kde.plasma.networkmanagement"
                  "org.kde.plasma.volume"
                ];
                hidden = [];
              };
            }
            {
              digitalClock = {
                calendar.firstDayOfWeek = "monday";
                time.format = "24h";
              };
            }
          ];
        }
      ];
    };
  };
}
