# enables `nix run .#vm`. it is very useful to have a VM
# you can edit your config and launch the VM to test stuff
# instead of having to reboot each time.
{
  den,
  lib,
  inputs,
  __findFile ? __findFile,
  ...
}: {
  den.aspects.vm = {
    includes = [(<den/tty-autologin> "m00n")];

    nixos = {
      config,
      pkgs,
      ...
    }: {
      virtualisation.vmVariant = {
        boot.loader.systemd-boot.enable = false;
        system.stateVersion = config.system.nixos.release;

        # fileSystems."/" = {
        #   fsType = "auto";
        #   device = "/dev/fake";
        # };
        # disko.devices.disk.root.content = lib.mkForce null;
      };
    };
  };

  den.aspects.tide.includes = [den.aspects.vm];
  perSystem = {pkgs, ...}: {
    packages.vm = pkgs.writeShellApplication {
      name = "vm";
      text = let
        host = inputs.self.nixosConfigurations.tide.config;
      in ''
        ${host.system.build.vm}/bin/run-${host.networking.hostName}-vm "$@"
      '';
    };
  };
}
