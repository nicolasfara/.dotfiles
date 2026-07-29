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
        "julia" = { id = "OCMKFZ4-XQ3LLXM-G4L3HYA-KOKRMEE-RF34KVT-3QVEBJI-BED73BR-JY624Q5"; };
      };
      folders = {
        "Documents" = {
          path = "${config.home.homeDirectory}/Documents";
          devices = [ "alice" "julia" ];
          ignorePerms = false;
          ignorePatterns = [
            ".DS_Store"
            ".git"
            ".gitignore"
            ".idea"
            "**/node_modules"
            "**/vendor"
            # Ignore specific folders
            "**/repos"
          ];
        };
      };
    };
  };
}
