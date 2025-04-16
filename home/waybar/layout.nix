{...}: {
  programs.waybar.settings.mainBar = {
    "modules-left" = ["sway/workspaces"];
    "modules-center" = ["sway/window"];
    "modules-right" = [
      "tray"
      "network"
      # "memory"
      # "cpu"
      "bluetooth"
      "battery"
      # "disk"
      "wireplumber"
      "clock"
    ];
  };
}
