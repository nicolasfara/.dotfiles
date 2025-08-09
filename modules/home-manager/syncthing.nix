{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    syncthing
  ];

  services.syncthing = {
    enable = true;

    settings = {
      gui = {
        user = "nicolas";
        passwordFile = config.sops.secrets.syncthing_password.path;
      };
      devices = {
        "alice" = { id = "Q3WRVS2-WM635OS-7ZCFL7V-4ZWBUA2-W6PM4C4-DVY43KB-GM5XFH2-JZAZFQL"; };
        "android" = { id = "XUEC4SS-EGFL3SZ-EREYLUV-GBA7O2Z-EPIU4SO-A7XB4BV-46NYGSS-IUYVLQ4"; };
        # "julia" = { id = ""; };
      };
      folders = {
        "Documents" = {
          path = "${config.home.homeDirectory}/Documents";
          devices = [ "alice" "android" /*"julia"*/ ];
          ignorePerms = false;
        };
      };
    };
  };
}
