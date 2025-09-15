{
	pkgs,
	config,
	lib,
	...
}: {
	imports = [];

	networking.timeServers = [
		"time.cloudflare.net"
		"ntp.zeitgitter.net"
		"ptbtime1.ptb.de"
		"ntp2.glypnod.com"
	];

	services.chrony = {
		enable = true;
		enableNTS = true;
		initstepslew.enabled = false;
		extraConfig = ''
			makestep 30 3
		'';
	};
}
