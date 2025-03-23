{
  config,
  lib,
  pkgs,
  ...
}: let
  uwsm-shell = pkgs.writeShellScriptBin "uwsm-shell" ''
    exec ${pkgs.app2unit}/bin/app2unit -- $(getent passwd $USER | cut -d: -f7)
  '';
in {
  home.packages = with pkgs; [
    app2unit
  ];

  programs.zsh.profileExtra = ''
    if uwsm check may-start; then
    	exec systemd-cat -t uwsm_start uwsm start default
    fi
  '';

  programs.alacritty.settings.terminal.shell = "${uwsm-shell}/bin/uwsm-shell";

  systemd.user.services = {
    swayidle.Service = {
      Type = lib.mkForce "exec";
      Slice = "background-graphical.slice"; # Assign to UWSM slice
    };
    waybar.Service = {
      Type = lib.mkForce "exec";
      Slice = "app-graphical.slice"; # Assign to UWSM slice
    };
    syncthingtray.Service.Slice = "background-graphical.slice";
    cliphist = {
      Service.Slice = "background-graphical.slice"; # Assign to UWSM slice
      Unit.After = ["graphical-session.target"];
    };
    # wluma.Service.Slice = "background-graphical.slice"; # Assign to UWSM slice
    gammastep.Service.Slice = "background-graphical.slice"; # Assign to UWSM slice
  };
}
