{
  lib,
  den,
  __findFile ? __findFile,
  ...
}: {
  den.default = {
    nixos.system.stateVersion = "26.05";
    homeManager.home.stateVersion = "26.05";
  };

  # enable hm by default
  den.schema.user.classes = lib.mkDefault ["homeManager"];

  den.default.includes = [
    <den/hostname>
    <den/define-user>

    <boot>
    <hardware/facter>
  ];

  # User TODO: REMOVE THIS
  den.aspects.m00n.nixos = {
    boot.loader.systemd-boot.enable = false;
    fileSystems."/".device = "/dev/fake";
    fileSystems."/".fsType = "auto";
  };
}
