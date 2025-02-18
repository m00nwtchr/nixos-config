{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
    ./desktop.nix
  ];

  networking.wireless.iwd.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  networking.nameservers = [
    "9.9.9.9#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
  ];

  environment.systemPackages = with pkgs; [
    # wluma
  ];

  systemd.user.services.wluma = {
    description = "Adjusting screen brightness based on screen contents and amount of ambient light";
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];

    serviceConfig = {
      ExecStart = "${pkgs.wluma}/bin/wluma";
      Restart = "always";
      PrivateNetwork = true;
      PrivateMounts = false;

      Slice = "app-graphical.slice";
    };

    wantedBy = ["graphical-session.target"];
  };

  services.auto-cpufreq = {
    enable = true;
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

  services.tlp = {
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
}
