# Port of legacy/modules/hardware/zfs.nix — enables ZFS support,
# derives networking.hostId from hosts/<host>/host-seed, sets the
# container storage driver to zfs. The host aspect (ganymede.nix)
# overrides the hostId with a fixed value to preserve the legacy
# ZFS pool hostId.
{
  __findFile ? __findFile,
  inputs,
  ...
}: {
  den.aspects.system.zfs = {
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      seedPath = "${inputs.self}/hosts/${config.networking.hostName}/host-seed";
    in {
      imports = [inputs.disko-zfs.nixosModules.default];

      virtualisation.containers.storage.settings.storage.driver = lib.mkOverride 999 "zfs";

      networking.hostId = builtins.substring 0 8 (
        builtins.hashString "sha256" (
          if builtins.pathExists seedPath
          then builtins.readFile seedPath
          else ""
        )
      );

      boot = {
        kernelPackages = lib.mkDefault pkgs.linuxPackages;
        supportedFilesystems = ["zfs"];
        zfs.package = pkgs.zfs_2_4;
      };

      services.zfs.autoScrub.enable = lib.mkDefault true;
    };
  };
}
