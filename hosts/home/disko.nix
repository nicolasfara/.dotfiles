{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_500GB_S4EVNX0N502363K";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "@" = { mountpoint = "/"; mountOptions = [ "compress=zstd" "noatime" ]; };
                    "@home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" "noatime" ]; };
                    "@nix" = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
                    "@log" = { mountpoint = "/var/log"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  };
                };
              };
            };
          };
        };
      };
      data = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S69ENX0W113955X";
        type = "disk";
        content = {
          type = "gpt";
          partitions.data = {
            size = "100%";
            content = {
              type = "btrfs";
              subvolumes = {
                "@containers" = { mountpoint = "/data/containers"; mountOptions = [ "compress=zstd" "nodatacow" ]; };
                "@yocto" = { mountpoint = "/data/yocto"; mountOptions = [ "compress=zstd" "nodatacow" ]; };
                "@projects" = { mountpoint = "/data/projects"; mountOptions = [ "compress=zstd" ]; };
              };
            };
          };
        };
      };
    };
  };
}