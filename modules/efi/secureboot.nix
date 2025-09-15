{
	pkgs,
	lib,
	username,
	...
}: {
	imports = [
		./default.nix
	];

	boot.loader.systemd-boot = {
		enable = lib.mkForce false;
		configurationLimit = 10;
		consoleMode = "max";
	};
	boot.lanzaboote = {
		enable = true;
		pkiBundle = "/var/lib/sbctl";
	};

	# Doesn't do anything/not supported by Lanzaboote yet.
	# boot.uki.settings = {
	#   "PCRSignature:initrd" = {
	#     PCRPrivateKey = "/var/lib/tpm2-pcr-private-key-initrd.pem";
	#     PCRPublicKey = "/var/lib/tpm2-pcr-public-key-initrd.pem";
	#     Phases = ["enter-initrd"];
	#   };
	#   "PCRSignature:system" = {
	#     PCRPrivateKey = "/var/lib/tpm2-pcr-private-key-system.pem";
	#     PCRPublicKey = "/var/lib/tpm2-pcr-public-key-system.pem";
	#     Phases = [
	#       "enter-initrd:leave-initrd"
	#       "enter-initrd:leave-initrd:sysinit"
	#       "enter-initrd:leave-initrd:sysinit:ready"
	#     ];
	#   };
	# };

	environment.systemPackages = [
		# For debugging and troubleshooting Secure Boot.
		pkgs.sbctl
	];
}
