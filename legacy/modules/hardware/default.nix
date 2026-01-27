{
	config,
	pkgs,
	lib,
	namespace,
	...
}: let
	wireless = config.${namespace}.hardware.facter.detected.wireless;
in {
	imports = [
		# ./btrfs.nix
		./nvidia.nix
		./facter.nix
	];

	networking.wireless.iwd = {
		enable = wireless;
		settings = {
			Network = {
				EnableIPv6 = true;
			};
		};
	};
	systemd.network.networks."25-wireless" =
		lib.mkIf wireless {
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

	hardware.wirelessRegulatoryDatabase = wireless;
	boot.extraModprobeConfig = ''
		options cfg80211 ieee80211_regdom="PL"
	'';

	hardware.bluetooth.powerOnBoot = !config.${namespace}.hardware.facter.detected.isLaptop;
}
