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
    nixos = {
      config,
      modulesPath,
      pkgs,
      ...
    }: {
      virtualisation.vmVariantWithDisko = {
        imports = [
          "${modulesPath}/profiles/qemu-guest.nix"
        ];
        system.stateVersion = config.system.nixos.release;
        disko.devices.disk.root.imageSize = "80G";

        boot.resumeDevice = lib.mkForce "";
        disko.devices.disk.root.content.partitions.root.content = lib.mkForce {
          type = "btrfs";
          subvolumes = {
            "@" = {
              mountpoint = "/";
              mountOptions = ["compress=zstd" "noatime"];
            };
            "@home" = {
              mountpoint = "/home";
              mountOptions = ["compress=zstd" "noatime"];
            };
            "@nix" = {
              mountpoint = "/nix";
              mountOptions = ["compress=zstd" "noatime"];
            };

            "@snapshots" = {
              mountpoint = "/.snapshots";
              mountOptions = ["compress=zstd" "noatime"];
            };
          };
        };
      };
    };
  };

  den.default.includes = [den.aspects.vm];
  perSystem = {pkgs, ...}: {
    packages =
      lib.mapAttrs'
      (
        name: host: {
          name = "${name}-vm";
          value = pkgs.writeShellApplication {
            name = "${name}-vm";
            text = ''
              ${host.config.system.build.vmWithDisko}/bin/disko-vm "$@"
            '';
          };
        }
      )
      inputs.self.nixosConfigurations;
  };
}
