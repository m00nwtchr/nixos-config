# Port of legacy/modules/sops-nix.nix — basic sops config (age
# sshKeyPaths) and defaultSopsFile path lookup.
{
  config,
  inputs,
  lib,
  ...
}: {
  den.aspects.system.sops = {
    nixos = {config, ...}: {
      sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

      sops.defaultSopsFile =
        let
          defaultSopsPath = "${inputs.self}/systems/${config.nixpkgs.hostPlatform.system}/${config.networking.hostName}/secrets/default.yaml";
        in
        lib.mkIf (builtins.pathExists defaultSopsPath) defaultSopsPath;
    };
  };
}
