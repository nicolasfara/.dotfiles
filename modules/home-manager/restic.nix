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
        # Set timeout to prevent hanging backups (4 hours)
        TimeoutStartSec = "4h";
        # Kill remaining processes after timeout
        KillMode = "mixed";
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
              HEALTHCHECKS_KEY="$(cat ${config.sops.secrets.healthchecks_alice.path})"
              HEALTHCHECKS_URL="https://hc-ping.com/$HEALTHCHECKS_KEY"

              # Create a temporary file for logs
              LOG_FILE=$(mktemp)
              trap "rm -f $LOG_FILE" EXIT

              # Notify healthchecks that backup is starting
              ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$HEALTHCHECKS_URL/start" || true

              # Function to check and handle repository locks
              check_and_unlock_repo() {
                echo "Checking repository status..." >> "$LOG_FILE"
                
                # Try to access repository, if it fails due to lock, unlock it
                if ! ${pkgs.restic}/bin/restic snapshots > /dev/null 2>&1; then
                  echo "Repository access failed, checking for locks..." >> "$LOG_FILE"
                  
                  # Check if it's a lock issue by trying to list locks
                  if ${pkgs.restic}/bin/restic list locks 2>&1 | grep -q "lock"; then
                    echo "Found repository locks, attempting to unlock..." >> "$LOG_FILE"
                    
                    # List current locks for logging
                    echo "Current locks:" >> "$LOG_FILE"
                    ${pkgs.restic}/bin/restic list locks 2>&1 | tee -a "$LOG_FILE" || true
                    
                    # Remove stale locks (older than 1 hour)
                    ${pkgs.restic}/bin/restic unlock 2>&1 | tee -a "$LOG_FILE"
                    
                    echo "Repository unlocked successfully" >> "$LOG_FILE"
                  else
                    echo "Repository issue is not related to locks, attempting init..." >> "$LOG_FILE"
                    ${pkgs.restic}/bin/restic init 2>&1 | tee -a "$LOG_FILE" || true
                  fi
                else
                  echo "Repository is accessible" >> "$LOG_FILE"
                fi
              }

              # Check and unlock repository if needed
              check_and_unlock_repo

              # Initialize repository if it doesn't exist (after potential unlock)
              ${pkgs.restic}/bin/restic snapshots > /dev/null 2>&1 || ${pkgs.restic}/bin/restic init

              # Create backup and capture output
              BACKUP_START=$(date +%s)
              echo "Backup started at $(date)" >> "$LOG_FILE"
              
              # Add backup timeout using the timeout command
              if timeout 3h ${pkgs.restic}/bin/restic backup \
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
                --exclude="dist" 2>&1 | tee -a "$LOG_FILE"; then
                echo "Backup completed successfully" >> "$LOG_FILE"
              else
                BACKUP_EXIT_CODE=$?
                if [ $BACKUP_EXIT_CODE -eq 124 ]; then
                  echo "Backup timed out after 3 hours" >> "$LOG_FILE"
                  # Try to unlock repository in case of timeout
                  ${pkgs.restic}/bin/restic unlock 2>&1 | tee -a "$LOG_FILE" || true
                  exit $BACKUP_EXIT_CODE
                else
                  echo "Backup failed with exit code: $BACKUP_EXIT_CODE" >> "$LOG_FILE"
                  exit $BACKUP_EXIT_CODE
                fi
              fi

              BACKUP_END=$(date +%s)
              DURATION=$((BACKUP_END - BACKUP_START))
              echo "Backup completed at $(date)" >> "$LOG_FILE"
              echo "Duration: $DURATION seconds" >> "$LOG_FILE"

              # Clean up old snapshots and capture output
              echo "Starting cleanup..." >> "$LOG_FILE"
              ${pkgs.restic}/bin/restic forget \
                --keep-daily 30 \
                --keep-weekly 12 \
                --keep-monthly 12 \
                --prune 2>&1 | tee -a "$LOG_FILE"

              # Get repository stats
              echo "Repository statistics:" >> "$LOG_FILE"
              ${pkgs.restic}/bin/restic stats --mode restore-size 2>&1 | tee -a "$LOG_FILE"

              # Send success notification with log data
              ${pkgs.curl}/bin/curl -fsS -m 30 --retry 5 \
                --data-binary "@$LOG_FILE" \
                --header "Content-Type: text/plain" \
                "$HEALTHCHECKS_URL" || true
            '';
          in
          "${resticScript}";

        # Add failure notification - only runs on failure
        ExecStopPost = pkgs.writeShellScript "restic-backup-failure" ''
          if [ "$SERVICE_RESULT" != "success" ]; then
            # Source the secrets for potential unlock
            export B2_ACCOUNT_ID="$(cat ${config.sops.secrets.backblaze_account_id.path})"
            export B2_ACCOUNT_KEY="$(cat ${config.sops.secrets.backblaze_account_key.path})"
            export RESTIC_REPOSITORY="b2:${cfg.bucketName}"
            export RESTIC_PASSWORD="$(cat ${config.sops.secrets.restic_password.path})"
            
            # Try to unlock repository in case backup failed due to interruption
            echo "Backup failed, attempting to unlock repository..."
            ${pkgs.restic}/bin/restic unlock || true
            
            HEALTHCHECKS_KEY="$(cat ${config.sops.secrets.healthchecks_alice.path})"
            HEALTHCHECKS_URL="https://hc-ping.com/$HEALTHCHECKS_KEY"
            
            # Create failure message
            ERROR_MSG="Restic backup failed on $(hostname) at $(date)
            Service result: $SERVICE_RESULT
            Repository has been unlocked to prevent future lock issues."

            ${pkgs.curl}/bin/curl -fsS -m 30 --retry 5 \
              --data "$ERROR_MSG" \
              --header "Content-Type: text/plain" \
              "$HEALTHCHECKS_URL/fail" || true
          fi
        '';

        # Security settings
        # ProtectHome = "read-only";
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

    # Service for manual repository maintenance and lock management
    systemd.user.services.restic-maintenance = {
      Unit = {
        Description = "Restic repository maintenance and lock management";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "oneshot";
        PrivateTmp = true;
        ExecStart = 
          let
            maintenanceScript = pkgs.writeShellScript "restic-maintenance" ''
              set -euo pipefail

              # Source the secrets
              export B2_ACCOUNT_ID="$(cat ${config.sops.secrets.backblaze_account_id.path})"
              export B2_ACCOUNT_KEY="$(cat ${config.sops.secrets.backblaze_account_key.path})"
              export RESTIC_REPOSITORY="b2:${cfg.bucketName}"
              export RESTIC_PASSWORD="$(cat ${config.sops.secrets.restic_password.path})"

              echo "Starting repository maintenance..."

              # Check repository status
              echo "Checking repository..."
              if ! ${pkgs.restic}/bin/restic snapshots > /dev/null 2>&1; then
                echo "Repository inaccessible, checking for locks..."
                
                # Force unlock if repository is locked
                echo "Unlocking repository..."
                ${pkgs.restic}/bin/restic unlock || true
                
                # Verify repository integrity
                echo "Checking repository integrity..."
                ${pkgs.restic}/bin/restic check --read-data-subset=5% || {
                  echo "Repository check failed, consider running full check manually"
                  exit 1
                }
              fi

              # List current locks
              echo "Current repository locks:"
              ${pkgs.restic}/bin/restic list locks || echo "No locks found"

              # Show repository statistics
              echo "Repository statistics:"
              ${pkgs.restic}/bin/restic stats --mode restore-size

              echo "Repository maintenance completed successfully"
            '';
          in
          "${maintenanceScript}";

        # Security settings
        ProtectHome = "read-only";
        ProtectSystem = "strict";
        NoNewPrivileges = true;
      };
    };
  };
}
