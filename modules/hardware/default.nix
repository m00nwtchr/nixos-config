{
	config,
	pkgs,
	lib,
	...
}: {
	imports = [
		./laptop.nix
		# ./btrfs.nix
		./nvidia.nix
		./facter.nix
	];

	networking.wireless.iwd = {
		enable = config.facter.detected.wireless;
		settings = {
			Network = {
				EnableIPv6 = true;
			};
		};
	};
	systemd.network.networks."25-wireless" =
		lib.mkIf config.facter.detected.wireless {
			matchConfig.WLANInterfaceType = "station";
			linkConfig.RequiredForOnline = "routable";
			networkConfig = {
				DHCP = true;
				IgnoreCarrierLoss = "3s";
				MulticastDNS = "resolve";
				IPv6PrivacyExtensions = true;
				IPv6AcceptRA = true;
			};
		};

	hardware.wirelessRegulatoryDatabase = config.facter.detected.wireless;
	boot.extraModprobeConfig = ''
		options cfg80211 ieee80211_regdom="PL"
	'';

	hardware.bluetooth.powerOnBoot = !config.facter.detected.isLaptop;
}
