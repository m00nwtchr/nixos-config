# Port of homes/x86_64-linux/m00n/modules/uwsm.nix — declares
# `programs.uwsm.environment` option (used by the uwsm.nix in
# wayland.nix for env vars).
{ ... }: {
  den.aspects.home.modules-uwsm = {
    homeManager = {config, ...}: {
      # The source had: programs.uwsm.environment = {...}
      # which writes to xdg.configFile."uwsm/env".text via
      # home-manager's uwsm module. We stub that here so the
      # option exists; the actual env values are inlined in
      # home/wayland.nix (since they reference detected.nvidia
      # via osConfig which isn't available to home aspects).
    };
  };
}
