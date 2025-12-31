{
	lib,
	pkgs,
	config,
	...
}: {
	sops.secrets."passwords/m00n".neededForUsers = true;

	users.users.m00n = {
		isNormalUser = true;
		uid = 1000;
		group = "m00n";
		shell = pkgs.zsh;

		hashedPasswordFile = config.sops.secrets."passwords/m00n".path;
		openssh.authorizedKeys.keyFiles = [../secrets/authorized_keys];

		extraGroups =
			[
				"wheel"
				"adbusers"
				"video"
			]
			++ (
				if config.security.tpm2.enable
				then ["tss"]
				else []
			);
	};
	users.groups.m00n.gid = 1000;

	sops.secrets.atuin_key = {
		sopsFile = ../secrets/atuin_key.txt;
		format = "binary";
		owner = config.users.users.m00n.name;
		group = config.users.users.m00n.group;
	};
	sops.secrets."atuin/session" = {
		owner = config.users.users.m00n.name;
		group = config.users.users.m00n.group;
	};

	sops.secrets."proton/password" = {
		sopsFile = ../secrets/proton.yaml;
		owner = config.users.users.m00n.name;
		group = config.users.users.m00n.group;
	};
	sops.secrets."proton/otp_secret_key" = {
		sopsFile = ../secrets/proton.yaml;
		owner = config.users.users.m00n.name;
		group = config.users.users.m00n.group;
	};


	home-manager.users.m00n = import ../home;
}
