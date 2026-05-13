{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}: let
  seedPath = "${inputs.self}/systems/${system}/${config.networking.hostName}/host-seed";
  seed = builtins.readFile seedPath;
in {
  virtualisation.containers.storage.settings.storage.driver = lib.mkOverride 999 "zfs";

  networking.hostId = builtins.substring 0 8 (
    builtins.hashString "sha256" seed
  );

  boot = {
    kernelPackages = lib.mkDefault pkgs.linuxPackages;
    supportedFilesystems = ["zfs"];
    zfs.package = pkgs.zfs_2_4;
  };

  services.zfs.autoScrub.enable = lib.mkDefault true;
}
