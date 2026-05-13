{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.virt-manager.enable = true;

  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      swtpm.enable = true;
      # ovmf.packages = [pkgs.OVMFFull.fd];
    };
  };

  users.groups.libvirtd.members = ["m00n"];
  users.groups.kvm.members = ["m00n"];

  environment.systemPackages = with pkgs; [
    # ... your other packages ...
    # gnome-boxes # VM management
    # dnsmasq # VM networking
    phodav # (optional) Share files with guest VMs
  ];

  networking.firewall.interfaces.virbr0.allowedUDPPorts = [53 67];
}
