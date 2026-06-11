# Host aspect for tide. Wires together the aspects that make up
# tide's NixOS configuration. Each `includes` reference is to
# another top-level den aspect (or a sub-aspect via `.name`).
{
  den,
  __findFile ? __findFile,
  ...
}:
{
  den.aspects.tide = {
    includes = [
      <boot>
      <system>
      <system/splash>
      <system/podman>
      <system/vms>
      <system/gaming>
      <system/rfkill-wlan0>
      <hardware/facter>
    ];

    # Tide-specific overrides go here. (Source equivalent:
    # systems/x86_64-linux/tide/default.nix.)
    nixos = {
      system.stateVersion = "26.05";
      networking.hostName = "tide";
    };

    # Provides: tide adds default packages to every user home on
    # this host. Source equivalent: home.packages = [pkgs.hello, pkgs.vim].
    provides.to-users.homeManager = {pkgs, ...}: {
      home.packages = [];
    };
  };
}
