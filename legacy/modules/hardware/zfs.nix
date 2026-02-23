{
	config,
	lib,
	pkgs,
	...
}: {
	virtualisation.containers.storage.settings.storage.driver = "zfs";

	boot.zfs.package = pkgs.zfs_2_4;
	services.zfs.autoScrub.enable = lib.mkDefault true;
}
