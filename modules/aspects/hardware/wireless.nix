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
        systemd.network.networks."25-wireless" = {
          matchConfig.WLANInterfaceType = "station";
          linkConfig.RequiredForOnline = "routable";
          networkConfig = {
            DHCP = "ipv4";
            IgnoreCarrierLoss = "3s";
            MulticastDNS = "resolve";
            IPv6PrivacyExtensions = true;
            IPv6AcceptRA = true;
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
}
