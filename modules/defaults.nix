{
  lib,
  den,
  __findFile ? __findFile,
  ...
}: {
  den.default = {
    nixos = {
      system.stateVersion = "26.11";
    };
    homeManager = {
      home.stateVersion = "26.11";
    };
  };

  # enable hm by default
  den.schema.user.classes = lib.mkDefault ["homeManager"];

  den.default.includes = [
    <den/hostname>
    <den/define-user>

    <system>
    <system/sops>
    <hardware/facter>
    <home-manager>

    <home/dotfiles>
  ];
}
