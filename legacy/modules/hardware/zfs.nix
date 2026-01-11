{
	config,
	lib,
	pkgs,
	...
}: {
	virtualisation.containers.storage.settings.storage.driver = "zfs";

	services.zfs.autoScrub.enable = lib.mkDefault true;
}
