{
	config,
	lib,
	pkgs,
	...
}: {
	programs.virt-manager.enable = true;
	users.groups.libvirtd.members = ["m00n"];
	virtualisation.libvirtd.enable = true;
}
