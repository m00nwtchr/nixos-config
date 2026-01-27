{
	config,
	lib,
	namespace,
	...
}:
with lib; let
	cfg = {
		enable =
			config.${namespace}.hardware.facter.detected.wireless;
	};
in {
	config =
		mkIf cfg.enable {
			networking.wireless.iwd = {
				enable = true;
				settings = {
					Network = {
						EnableIPv6 = true;
					};
				};
			};
			systemd.network.networks."25-wireless" = {
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

			hardware.wirelessRegulatoryDatabase = true;
			boot.extraModprobeConfig = ''
				options cfg80211 ieee80211_regdom="PL"
			'';

			hardware.bluetooth.powerOnBoot = !config.${namespace}.hardware.facter.detected.isLaptop;
		};
}
