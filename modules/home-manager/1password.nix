{
  lib,
  pkgs,
  config,
  ...
}:

let
  onePassPath = "~/.1password/agent.sock";
  cfg = config.programs.onepassword;
in
{
  options.programs.onepassword = {
    enable = lib.mkEnableOption "1Password Git integration";

    signingKey = lib.mkOption {
      type = lib.types.str;
      description = "SSH signing key for Git commits";
      example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPacHq6GiFIEA4o0D4B74K20je+KeSxkuIUvr6oF4wJ";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      extraConfig = ''
        Host *
            IdentityAgent ${onePassPath}
      '';
    };

    programs.git = {
      enable = true;
      extraConfig = {
        gpg = {
          format = "ssh";
        };
        "gpg \"ssh\"" = {
          program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
        };
        commit = {
          gpgsign = true;
        };

        user = {
          signingKey = cfg.signingKey;
        };
      };
    };
  };
}
