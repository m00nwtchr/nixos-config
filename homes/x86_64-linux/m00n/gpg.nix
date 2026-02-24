{
	config,
	lib,
	pkgs,
	...
}: {
	home.packages = with pkgs; [
		sequoia-sq
		sequoia-chameleon-gnupg
	];

	services.gpg-agent = {
		enable = true;
		enableSshSupport = true;
		enableExtraSocket = true;
	};
	programs.gpg = {
		enable = true;
		homedir = "${config.xdg.dataHome}/gnupg";
		scdaemonSettings = {
			card-timeout = "5";
			disable-ccid = true;
		};
		settings = {
			auto-key-locate = "local,wkd";
			keyserver-options = "auto-key-retrieve";
		};
	};
}
