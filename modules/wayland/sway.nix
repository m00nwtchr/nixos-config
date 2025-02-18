{
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
    ./default.nix
  ];

  programs.uwsm.enable = true;
  programs.uwsm.waylandCompositors.sway = {
    prettyName = "Sway";
    comment = "Sway compositor";
    binPath = "/run/current-system/sw/bin/sway";
  };

  programs.sway = {
    enable = true;
    xwayland.enable = false;
    extraPackages = [];
  };

  xdg.portal = {
    wlr.enable = true;
  };

  services = {
  };
}
