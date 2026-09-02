{...}: {
  den.aspects.home.waybar.modules = {
    homeManager = {
      pkgs,
      osConfig,
      ...
    }: let
      networkStatus = pkgs.writeShellScript "waybar-network-status" ''
        set -euo pipefail

        bond="bond0"
        wifi="wlan0"

        if [[ ! -e "/sys/class/net/$bond/bonding/active_slave" ]] ||
           [[ "$(cat "/sys/class/net/$bond/operstate")" != "up" ]]; then
          echo '{"alt":"disconnected","text":"Disconnected ⚠","tooltip":"Disconnected"}'
          exit 0
        fi

        ip_address="$(${pkgs.iproute2}/bin/ip -4 addr show dev "$bond" |
          ${pkgs.gawk}/bin/awk '/inet / {print $2; exit}')"

        active_slave="$(<"/sys/class/net/$bond/bonding/active_slave")"

        if [[ "$active_slave" == "$wifi" ]]; then
          link="$(${pkgs.iw}/bin/iw dev "$wifi" link)"

          ssid="$(printf '%s\n' "$link" |
            ${pkgs.gawk}/bin/awk -F'SSID: ' '/SSID:/ {print $2}')"

          signal_dbm="$(printf '%s\n' "$link" |
            ${pkgs.gawk}/bin/awk '/signal:/ {print $2}')"

          # Roughly map -90..-30 dBm to 0..100%.
          signal_pct=$(( (signal_dbm + 90) * 100 / 60 ))

          (( signal_pct < 0 )) && signal_pct=0
          (( signal_pct > 100 )) && signal_pct=100

          ${pkgs.coreutils}/bin/printf \
            '{"alt":"wifi","text":"  %d%%","tooltip":"%s\\n%s (%s dBm)"}\n' \
            "$signal_pct" "$ip_address" "$ssid" "$signal_dbm"

        elif [[ -n "$active_slave" && "$active_slave" != "None" ]]; then
          ${pkgs.coreutils}/bin/printf \
            '{"alt":"ethernet","text":"󰈁 Connected","tooltip":"%s"}\n' \
            "$ip_address"

        else
          echo '{"alt":"disconnected","text":"Disconnected ⚠","tooltip":"Disconnected"}'
        fi
      '';
    in {
      programs.waybar.settings.mainBar = {
        "sway/workspaces" = {
          on-click = "activate";
          persistent-workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
          };
        };

        clock = {
          format = "{:%H:%M}";
          tooltip-format = "{calendar}";
          # locale = "en_GB.UTF-8";
          calendar = {
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ffcc66'><b><u>{}</u></b></span>";
            };
          };
        };

        wireplumber = {
          format = "{icon} {volume}%";
          tooltip = false;
          format-muted = " Muted";
          on-click = "wpctl set-mute @DEFAULT_SINK@ toggle";
          on-click-right = "pavucontrol";
          on-scroll-up = "wpctl set-volume -l 1 @DEFAULT_SINK@ 5%+";
          on-scroll-down = "wpctl set-volume @DEFAULT_SINK@ 5%-";
          scroll-step = 5;
          format-icons = {
            headphone = "";
            "hands-free" = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
        };

        "custom/network" = {
          exec = "${networkStatus}";
          return-type = "json";
          interval = 2;
          format = "{}";
        };

        network = {
          format-wifi = "  {signalStrength}%";
          format-ethernet = "󰈁 Connected";
          tooltip-format = "{essid} - {ifname} via {gwaddr}";
          format-linked = "{ifname} (No IP)";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}:{essid} {ipaddr}/{cidr}";
        };

        bluetooth = {
          format = " {status}";
          format-disabled = " off";
          format-connected = " {num_connections}";
          tooltip-format = "{device_alias}";
          tooltip-format-connected = " {device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
          on-click = "bluetooth toggle";
        };

        memory = {
          interval = 5;
          format = "Mem {}%";
        };

        cpu = {
          interval = 5;
          format = "CPU {usage:2}%";
        };

        battery = {
          states = {
            good = 80;
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{time} {icon}";
          format-icons = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
        };

        disk = {
          interval = 5;
          format = "Disk {percentage_used:2}%";
          path = "/";
        };

        tray = {
          icon-size = 18;
          spacing = 10;
        };
      };
    };
  };
}
