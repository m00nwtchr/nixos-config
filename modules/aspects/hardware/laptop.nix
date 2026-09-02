{
  den,
  hardware,
  pkgs,
  lib,
  ...
}: {
  hardware.laptop = {
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      options.den.aspects.laptop.enable =
        lib.mkEnableOption "Laptop settings"
        // {
          default = config.hardware.facter.detected.isLaptop;
        };

      config = lib.mkIf config.den.aspects.laptop.enable {
        # systemd.targets = {
        #   ac = {
        #     description = "AC Power Profile";
        #     unitConfig = {
        #       Conflicts = ["battery.target"];
        #       DefaultDependencies = false;
        #     };
        #   };
        #   battery = {
        #     description = "Battery Power Profile";
        #     unitConfig = {
        #       Conflicts = ["ac.target"];
        #       DefaultDependencies = false;
        #     };
        #   };
        # };

        systemd.services = let
          smtCtl = "/sys/devices/system/cpu/smt/control";

          mkSmtScript = state:
            pkgs.writeShellScript "smt-${state}" ''
              set -eu
              if [ -w ${smtCtl} ]; then
                printf "%s\n" ${state} > ${smtCtl}
              fi
            '';
        in {
          # tailscaled.wantedBy = lib.mkForce [];
        };

        services.udev.extraRules = ''
          # ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", TAG+="systemd", \
          #   ENV{POWER_SUPPLY_ONLINE}=="1", ENV{SYSTEMD_WANTS}+="ac.target"

          # ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", TAG+="systemd", \
          #   ENV{POWER_SUPPLY_ONLINE}=="0", ENV{SYSTEMD_WANTS}+="battery.target"

          ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
          ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
          ACTION=="add", SUBSYSTEM=="leds", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/leds/%k/brightness"
          ACTION=="add", SUBSYSTEM=="leds", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/%k/brightness"
        '';

        services = {
          logind.settings = {
            Login = {
              HandleLidSwitch = "suspend-then-hibernate";
              HandleLidSwitchExternalPower = "lock";
              HandleLidSwitchDocked = "ignore";
            };
          };

          upower = {
            enable = true;
            usePercentageForPolicy = true;

            percentageLow = 20;
            percentageCritical = 15;
            percentageAction = 10;

            criticalPowerAction = "HybridSleep";
          };

          networkd-dispatcher = {
            enable = false;
            rules = let
              systemctl = "${pkgs.systemd}/bin/systemctl";
              systemdCat = "${pkgs.systemd}/bin/systemd-cat";
              ip = "${pkgs.iproute2}/bin/ip";

              startTailscale = pkgs.writeShellScript "tailscale-start-routable" ''
                set -euo pipefail
                echo "network became routable -> starting tailscaled" | ${systemdCat} -t tailscale-power
                ${systemctl} start tailscaled.service
              '';

              stopTailscaleIfOffline = pkgs.writeShellScript "tailscale-stop-offline" ''
                set -euo pipefail

                sleep 2

                if ${ip} -4 route show default | grep -vq ' dev tailscale0' || \
                   ${ip} -6 route show default | grep -vq ' dev tailscale0'
                then
                  exit 0
                fi

                echo "no non-tailscale default route -> stopping tailscaled" | ${systemdCat} -t tailscale-power
                ${systemctl} stop tailscaled.service
              '';
            in {
              "stop-services" = {
                onState = ["off" "degraded"];
                script = ''
                  #!${pkgs.runtimeShell}
                  ${stopTailscaleIfOffline}
                '';
              };
              "start-services" = {
                onState = ["routable"];
                script = ''
                  #!${pkgs.runtimeShell}
                  ${startTailscale}
                '';
              };
            };
          };

          tlp = {
            enable = true;
            settings = {
              START_CHARGE_THRESH_BAT0 = 40;
              STOP_CHARGE_THRESH_BAT0 = 80;
            };
          };
        };
      };
    };
  };
}
