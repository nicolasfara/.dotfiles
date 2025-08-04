{ config, ... }:
{
  sops = {
    age.keyFile = "/home/nicolas/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets.yaml;

    secrets = {
      backblaze_account_id = {
        path = "${config.sops.defaultSymlinkPath}/backblaze_account_id";
      };
      backblaze_account_key = {
        path = "${config.sops.defaultSymlinkPath}/backblaze_account_key";
      };
      restic_password = {
        path = "${config.sops.defaultSymlinkPath}/restic_password";
      };
    };
  };
}
