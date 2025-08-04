{ config, lib, ... }:

with lib;

let
  cfg = config.services.sanoidService;
in
{
  options.services.sanoidService = {
    enable = mkEnableOption "Enable Sanoid ZFS snapshot management";

    datasets = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            template = mkOption {
              type = types.str;
              default = "backup";
              description = "Template to use for this dataset";
            };
            recursive = mkOption {
              type = types.bool;
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

    templates = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            frequently = mkOption {
              type = types.int;
              default = 4;
              description = "Number of frequent snapshots to keep (every 15 minutes)";
            };
            hourly = mkOption {
              type = types.int;
              default = 24;
              description = "Number of hourly snapshots to keep";
            };
            daily = mkOption {
              type = types.int;
              default = 7;
              description = "Number of daily snapshots to keep";
            };
            monthly = mkOption {
              type = types.int;
              default = 12;
              description = "Number of monthly snapshots to keep";
            };
            yearly = mkOption {
              type = types.int;
              default = 0;
              description = "Number of yearly snapshots to keep";
            };
            autosnap = mkOption {
              type = types.bool;
              default = true;
              description = "Enable automatic snapshot creation";
            };
            autoprune = mkOption {
              type = types.bool;
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

  config = mkIf cfg.enable {
    services.sanoid = {
      enable = true;
      datasets = mapAttrs (name: dataset: {
        useTemplate = [ dataset.template ];
        recursive = dataset.recursive;
      }) cfg.datasets;
      templates = cfg.templates;
    };
  };
}
