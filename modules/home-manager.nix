{
	config,
	pkgs,
	lib,
	username,
	...
}: {
	home-manager.useGlobalPkgs = true;
	home-manager.useUserPackages = true;

	home-manager.backupFileExtension = "bak";
}
