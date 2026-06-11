{
  den,
  __findFile ? __findFile,
  ...
}: {
  # user aspect
  den.aspects.m00n = {
    includes = [
      <den/primary-user>
      (<den/user-shell> "zsh")
    ];

    homeManager = {pkgs, ...}: {
      home.packages = [pkgs.htop];
    };

    # user can provide NixOS configurations
    # to any host it is included on
    provides.to-hosts.nixos = {pkgs, ...}: {};
  };
}
