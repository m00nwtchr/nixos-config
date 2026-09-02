{
  pkgs,
  lib,
  ...
}: {
  den.aspects.system.autologin = {
    nixos = {
      config,
      pkgs,
      ...
    }: let
      username = "m00n";
    in {
      systemd.services."getty@tty1" = {
        overrideStrategy = "asDropin";
        serviceConfig.ExecStart = [
          ""
          "@${pkgs.util-linux}/sbin/agetty agetty --skip-login --nonewline --noissue --autologin ${username} --noreset --noclear --keep-baud %I 115200,38400,9600 $TERM"
        ];
      };
    };
  };
}
