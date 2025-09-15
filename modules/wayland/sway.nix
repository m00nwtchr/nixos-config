{
	pkgs,
	lib,
	username,
	...
}: {
	imports = [
		./default.nix
	];

	programs.uwsm = {
		enable = true;
		waylandCompositors.sway = {
			prettyName = "Sway";
			comment = "Sway compositor";
			binPath = "/run/current-system/sw/bin/sway";
		};
	};

	programs.sway = {
		enable = true;
		xwayland.enable = true;
		wrapperFeatures.gtk = true;
		extraPackages = [];
	};

	xdg.portal = {
		wlr.enable = true;
	};

	services = {
	};
}
