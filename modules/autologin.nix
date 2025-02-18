{
  pkgs,
  lib,
  username,
  ...
}: {
  systemd.services."autovt@tty1" = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      Type = "simple";
      Environment = ["XDG_SESSION_TYPE=wayland"];
      ExecStart = ["" "${pkgs.util-linux}/sbin/agetty --login-program ${pkgs.shadow}/bin/login -o \'-p -f -- \\\\u\' --noclear --autologin m00n %I $TERM"];
    };
  };
}
