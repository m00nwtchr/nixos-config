{
	config,
	osConfig,
	lib,
	pkgs,
	...
}: {
	programs.rclone = {
		enable = false;
		remotes = {
			protondrive = {
				config = {
					type = "protondrive";
					username = "lmarianski";
					enable-caching = false;
				};
				secrets = {
					password = osConfig.sops.secrets."proton/password".path;
					# otp_secret_key = osConfig.sops.secrets."proton/otp_secret_key".path;
				};
				mounts."/" = {
					enable = true;
					mountPoint = "${config.home.homeDirectory}/Proton";
					options = {
						cache-dir = "${config.xdg.cacheHome}/rclone";
						vfs-cache-mode = "full";
					};
				};
			};
		};
	};
}
