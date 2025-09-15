{
  pkgs,
  lib,
  username,
  ...
}:
{
  boot.initrd.systemd.enable = true;

  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.systemd-boot = {
    enable = lib.mkDefault true;
    configurationLimit = 10;
    consoleMode = "max";
  };
}
