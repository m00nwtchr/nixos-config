{
	config,
	pkgs,
	lib,
	inputs,
	username,
	...
}: {
	imports = [
	];

	environment.systemPackages = with pkgs; [
	];

	security.pam.services.greetd = {
		u2fAuth = true;
	};

	services.greetd = {
		enable = true;
		settings = {
			default_session = {
				# TUI (tiny, fastest):
				command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'systemd-cat -t uwsm_start uwsm start default'";
				# GUI (still light, smooth handoff from splash):
				# command = "${pkgs.cage}/bin/cage -- ${pkgs.greetd.regreet}/bin/regreet";
				user = "greeter";
			};
		};
	};
}
