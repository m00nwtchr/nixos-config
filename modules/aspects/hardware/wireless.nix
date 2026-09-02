{
  den,
  hardware,
  lib,
  ...
}: {
  hardware.wireless = {
    nixos = {config, ...}:
      lib.mkIf config.hardware.facter.detected.wireless {
        networking.wireless.iwd = {
          enable = true;
          settings = {
            Network = {
              EnableIPv6 = true;
            };
          };
        };

        hardware.wirelessRegulatoryDatabase = true;
        boot.extraModprobeConfig = ''
          options cfg80211 ieee80211_regdom="PL"
        '';

        hardware.bluetooth = {
          powerOnBoot = !config.hardware.facter.detected.isLaptop;
          settings.General = {
            Experimental = true;
            KernelExperimental = true;
          };
        };
      };
  };

  hardware.network = {
    includes = [hardware.wireless];
    nixos = {config, ...}: let
      bond = true;

      addressConfig = {
        DHCP = "ipv4";
        MulticastDNS = "resolve";
        IPv6PrivacyExtensions = true;
        IPv6AcceptRA = true;
      };
    in {
      systemd.network.networks."25-wireless" = lib.mkIf config.hardware.facter.detected.wireless {
        matchConfig.WLANInterfaceType = "station";
        linkConfig.RequiredForOnline = lib.mkIf (!bond) "routable";
        networkConfig = (
          {
            IgnoreCarrierLoss = "3s";
          }
          // (
            if bond
            then {
              Bond = "bond0";
            }
            else addressConfig
          )
        );
      };
      systemd.network.networks."25-ethernet" = lib.mkIf config.hardware.facter.detected.wireless {
        matchConfig.Name = "en*";
        networkConfig =
          if bond
          then {
            Bond = "bond0";
            PrimarySlave = true;
          }
          else addressConfig;
      };

      systemd.network.netdevs."10-bond0" = lib.mkIf bond {
        netdevConfig.Name = "bond0";
        netdevConfig.Kind = "bond";

        bondConfig = {
          Mode = "active-backup";
          PrimaryReselectPolicy = "always";
          MIIMonitorSec = "1s";
        };
      };
      systemd.network.networks."30-bond0" = lib.mkIf bond {
        matchConfig.Name = "bond0";
        linkConfig.RequiredForOnline = "routable";
        networkConfig = addressConfig;
      };
    };
  };
}
