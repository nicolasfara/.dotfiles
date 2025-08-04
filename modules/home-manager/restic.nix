{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.restic;
in
{
  options = {
    programs.restic = {
      bucketName = lib.mkOption {
        type = lib.types.str;
        description = "Backblaze B2 bucket name for restic backups";
        example = "my-backup-bucket";
      };
    };
  };

  config = {
    # Install restic
    home.packages = with pkgs; [
      restic
    ];

    # Configure systemd service for restic backup
    systemd.user.services.restic-backup = {
      Unit = {
        Description = "Restic backup to Backblaze B2";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "oneshot";
        PrivateTmp = true;
        # ExecStartPre = "${pkgs.coreutils}/bin/sleep 30";
        ExecStart =
          let
            resticScript = pkgs.writeShellScript "restic-backup" ''
              set -euo pipefail

              # Source the secrets
              export B2_ACCOUNT_ID="$(cat ${config.sops.secrets.backblaze_account_id.path})"
              export B2_ACCOUNT_KEY="$(cat ${config.sops.secrets.backblaze_account_key.path})"
              export RESTIC_REPOSITORY="b2:${cfg.bucketName}"
              export RESTIC_PASSWORD="$(cat ${config.sops.secrets.restic_password.path})"

              # Initialize repository if it doesn't exist
              ${pkgs.restic}/bin/restic snapshots || ${pkgs.restic}/bin/restic init

              # Create backup
              ${pkgs.restic}/bin/restic backup \
                --verbose \
                --tag "$(hostname)" \
                --tag "$(date +%Y-%m-%d)" \
                ${config.home.homeDirectory}/Documents \
                ${config.home.homeDirectory}/Pictures \
                ${config.home.homeDirectory}/Music \
                ${config.home.homeDirectory}/Videos \
                ${config.home.homeDirectory}/.dotfiles \
                ${config.home.homeDirectory}/.ssh \
                ${config.home.homeDirectory}/.gnupg \
                --exclude="*.tmp" \
                --exclude="*.cache" \
                --exclude="node_modules" \
                --exclude=".git" \
                --exclude="target" \
                --exclude="build" \
                --exclude="dist"

              # Clean up old snapshots (keep last 30 daily, 12 weekly, 12 monthly)
              ${pkgs.restic}/bin/restic forget \
                --keep-daily 30 \
                --keep-weekly 12 \
                --keep-monthly 12 \
                --prune
            '';
          in
          "${resticScript}";

        # Security settings
        ProtectHome = "read-only";
        ProtectSystem = "strict";
        NoNewPrivileges = true;

        # Restart on failure
        Restart = "on-failure";
        RestartSec = "5min";
      };
    };

    # Timer to run backup daily
    systemd.user.timers.restic-backup = {
      Unit = {
        Description = "Run restic backup daily";
        Requires = [ "restic-backup.service" ];
      };

      Timer = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "10min";
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
