# Port of homes/x86_64-linux/m00n/autostart.nix — safeeyes
# autostart + tray dependency.
{pkgs, ...}: {
  den.aspects.home.autostart = {
    homeManager = {
      pkgs,
      config,
      ...
    }: {
      home.packages = with pkgs; [
        safeeyes
      ];

      xdg.autostart.entries = [
        "${pkgs.safeeyes}/share/applications/io.github.slgobinath.SafeEyes.desktop"
      ];
      xdg.configFile."systemd/user/app-io.github.slgobinath.SafeEyes@autostart.service.d/override.conf".text = ''
        [Unit]
        Requires=tray.target
        After=tray.target
      '';
    };
  };
}
