{
	pkgs,
	config,
	lib,
	username,
	...
}: let
	enable = config.boot.plymouth.enable;
in {
	boot = {
		plymouth = {
			enable = lib.mkDefault true;
			theme = "dna";

			themePackages = with pkgs; [
				(adi1090x-plymouth-themes.override {
						selected_themes = ["dna"];
					})
			];
		};

		consoleLogLevel = lib.mkIf enable 3;
		initrd.verbose = lib.mkIf enable false;
		loader.timeout = lib.mkIf enable 0;

		kernelParams =
			lib.mkIf enable [
				"quiet"
				"splash"
				"systemd.show_status=auto"
				"udev.log_level=3"
				"vt.global_cursor_default=0"
			];
		kernel.sysctl =
			lib.mkIf enable {
				"kernel.printk" = "3 3 3 3";
			};
	};
}
