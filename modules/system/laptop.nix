{
  config,
  pkgs,
  lib,
  username,
  ...
}: let
  isLaptop = config.facter.detected.isLaptop;
in {
  imports = [
    ./desktop.nix
    # ../chrony.nix
  ];

  networking.wireless.iwd.enable = config.facter.detected.wireless;
  hardware.bluetooth.powerOnBoot = !isLaptop;

  networking.nameservers = lib.mkIf isLaptop [
    "9.9.9.9#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
  ];

  systemd.network.networks."25-wireless" = lib.mkIf config.facter.detected.wireless {
    matchConfig.WLANInterfaceType = "station";
    linkConfig.RequiredForOnline = "routable";
    networkConfig = {
      DHCP = true;
      IgnoreCarrierLoss = "3s";
      MulticastDNS = "resolve";
    };
  };

  # environment.systemPackages = with pkgs; [];

  systemd.targets = lib.mkIf isLaptop {
    ac = {
      description = "AC power";
      unitConfig = {
        Conflicts = ["battery.target"];
        DefaultDependencies = false;
        # StopWhenUnneeded = true;
      };
    };
    battery = {
      description = "Battery power";
      unitConfig = {
        Conflicts = ["ac.target"];
        DefaultDependencies = false;
        # StopWhenUnneeded = true;
      };
    };
  };

  services.udev.extraRules = lib.mkIf isLaptop ''
    SUBSYSTEM=="power_supply", KERNEL=="AC?", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl start battery.target"
    SUBSYSTEM=="power_supply", KERNEL=="AC?", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl start ac.target"
  '';

  services = {
    logind = {
      powerKey = "suspend-then-hibernate";
      lidSwitch = "suspend-then-hibernate";
      extraConfig = ''
        HibernateDelaySec=900
      '';
    };

    auto-cpufreq = {
      enable = isLaptop;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };

    tlp = {
      # enable = lib.mkDefault true;
      enable = false;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        PLATFORM_PROFILE_ON_BAT = "low-power";
        PLATFORM_PROFILE_ON_AC = "performance";

        USB_AUTOSUSPEND = 0;

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
  };
}
