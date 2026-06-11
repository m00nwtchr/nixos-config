# Port of legacy/modules/vms.nix — virt-manager + libvirtd.
{
  config,
  lib,
  pkgs,
  ...
}: {
  den.aspects.vms = {
    nixos = {
      programs.virt-manager.enable = true;

      virtualisation.libvirtd = {
        enable = true;

        qemu = {
          swtpm.enable = true;
        };
      };

      users.groups.libvirtd.members = ["m00n"];
      users.groups.kvm.members = ["m00n"];

      environment.systemPackages = with pkgs; [
        phodav
      ];

      networking.firewall.interfaces.virbr0.allowedUDPPorts = [53 67];
    };
  };
}
