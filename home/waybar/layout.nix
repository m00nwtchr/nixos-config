{
  lib,
  osConfig,
  ...
}: {
  programs.waybar.settings.mainBar = {
    "modules-left" = ["sway/workspaces"];
    "modules-center" = ["sway/window"];
    "modules-right" = [
      "tray"
      "network"
      # "memory"
      # "cpu"
      (lib.mkIf osConfig.hardware.bluetooth.enable "bluetooth")
      "battery"
      # "disk"
      "wireplumber"
      "clock"
    ];
  };
}
