# Port of legacy/modules/sops-nix.nix — basic sops config (age
# sshKeyPaths) and defaultSopsFile path lookup.
{
  config,
  inputs,
  lib,
  ...
}: {
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.system.sops = {
    nixos = {config, ...}: {
      imports = [inputs.sops-nix.nixosModules.sops];

      sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

      sops.defaultSopsFile = let
        defaultSopsPath = "${inputs.self}/hosts/${config.networking.hostName}/secrets/default.yaml";
      in
        lib.mkIf (builtins.pathExists defaultSopsPath) defaultSopsPath;
    };
  };
}
