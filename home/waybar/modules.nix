{...}: {
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
        default = ["" "" ""];
      };
    };

    network = {
      format-wifi = "  {signalStrength}%";
      format-ethernet = "{ipaddr}/{cidr}";
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
      format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
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
}
