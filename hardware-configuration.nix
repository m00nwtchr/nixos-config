# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
	config,
	lib,
	pkgs,
	modulesPath,
	...
}: {
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
	];

	boot.initrd.availableKernelModules = [
		"nvme"
		"xhci_pci"
		"ahci"
		"usbhid"
		"rtsx_usb_sdmmc"
		"amdgpu"
		"asus_wmi"
	];
	boot.initrd.kernelModules = [];
	boot.kernelModules = ["kvm-amd"];
	boot.extraModulePackages = [];

	boot.loader.efi.efiSysMountPoint = "/efi";

	fileSystems."/" = {
		device = "/dev/mapper/root";
		fsType = "btrfs";
		options = [
			"subvol=@"
			"compress=zstd"
		];
	};

	boot.initrd.luks.devices."root".device = "/dev/disk/by-uuid/7790403a-8bbc-4cbd-9bf6-252716a9be06";

	fileSystems."/efi" = {
		device = "/dev/disk/by-uuid/522B-7F0C";
		fsType = "vfat";
		options = [
			"fmask=0022"
			"dmask=0022"
			"umask=0077"
		];
	};

	fileSystems."/home" = {
		device = "/dev/mapper/root";
		fsType = "btrfs";
		options = [
			"subvol=@home"
			"compress=zstd"
		];
	};

	fileSystems."/nix/store" = {
		device = "/dev/mapper/root";
		fsType = "btrfs";
		options = [
			"subvol=@nix_store"
			"compress=zstd"
		];
	};

	fileSystems."/.snapshots" = {
		device = "/dev/mapper/root";
		fsType = "btrfs";
		options = [
			"subvol=@snapshots"
			"compress=zstd"
		];
	};

	swapDevices = [];

	# Enables DHCP on each ethernet and wireless interface. In case of scripted networking
	# (the default) this is the recommended approach. When using systemd-networkd it's
	# still possible to use this option, but it's recommended to use it in conjunction
	# with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
	#networking.useDHCP = lib.mkDefault true;
	# networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;

	nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
	hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}