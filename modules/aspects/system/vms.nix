# Port of legacy/modules/vms.nix — virt-manager + libvirtd.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  den.aspects.system.vms = {
    nixos = {pkgs, ...}: {
      imports = [inputs.microvm.nixosModules.host];

      microvm.host.useNotifySockets = true;
      # microvm.vms = {
      #   opencode = {
      #     autostart = false;
      #     config = {
      #       microvm.hypervisor = "cloud-hypervisor";
      #       microvm.vsock.cid = 42;
      #       microvm.shares = [
      #         {
      #           source = "/nix/store";
      #           mountPoint = "/nix/.ro-store";
      #           tag = "ro-store";
      #           proto = "virtiofs";
      #         }
      #       ];
      #     };
      #   };
      # };

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
        # phodav
      ];

      # networking.bridges.br0.interfaces = ["wlan0"];
      networking.firewall.interfaces.virbr0.allowedUDPPorts = [53 67];
    };
  };
}
