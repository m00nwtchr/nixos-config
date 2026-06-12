{
  lib,
  den,
  __findFile ? __findFile,
  ...
}: {
  den.default = {
    nixos = {
      system.stateVersion = "26.05";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.permittedInsecurePackages = [
        "olm-3.2.16"
        "libsoup-2.74.3"
        "electron-39.8.10"
      ];
    };
    homeManager = {
      home.stateVersion = "26.05";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.permittedInsecurePackages = [
        "olm-3.2.16"
        "libsoup-2.74.3"
        "electron-39.8.10"
      ];
    };
  };

  # enable hm by default
  den.schema.user.classes = lib.mkDefault ["homeManager"];

  den.default.includes = [
    <den/hostname>
    <den/define-user>

    <hardware/facter>
  ];
}
