{ config, lib, ... }:

let
  cfg = config.services.sanoidService;
in
{
  options.services.sanoidService = {
    enable = lib.mkEnableOption "Enable Sanoid ZFS snapshot management";

    datasets = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            template = lib.mkOption {
              type = lib.types.str;
              default = "backup";
              description = "Template to use for this dataset";
            };
            recursive = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Apply snapshots recursively to child datasets";
            };
          };
        }
      );
      default = { };
      description = "ZFS datasets to manage with Sanoid";
      example = {
        "rpool/home" = {
          template = "backup";
          recursive = true;
        };
      };
    };

    templates = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            frequently = lib.mkOption {
              type = lib.types.int;
              default = 4;
              description = "Number of frequent snapshots to keep (every 15 minutes)";
            };
            hourly = lib.mkOption {
              type = lib.types.int;
              default = 24;
              description = "Number of hourly snapshots to keep";
            };
            daily = lib.mkOption {
              type = lib.types.int;
              default = 7;
              description = "Number of daily snapshots to keep";
            };
            monthly = lib.mkOption {
              type = lib.types.int;
              default = 12;
              description = "Number of monthly snapshots to keep";
            };
            yearly = lib.mkOption {
              type = lib.types.int;
              default = 0;
              description = "Number of yearly snapshots to keep";
            };
            autosnap = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable automatic snapshot creation";
            };
            autoprune = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable automatic snapshot pruning";
            };
          };
        }
      );
      default = {
        backup = {
          frequently = 4;
          hourly = 24;
          daily = 7;
          monthly = 12;
          yearly = 0;
          autosnap = true;
          autoprune = true;
        };
      };
      description = "Sanoid templates for snapshot policies";
    };
  };

  config = lib.mkIf cfg.enable {
    services.sanoid = {
      enable = true;
      datasets = lib.mapAttrs (name: dataset: {
        useTemplate = [ dataset.template ];
        recursive = dataset.recursive;
      }) cfg.datasets;
      templates = cfg.templates;
    };
  };
}
