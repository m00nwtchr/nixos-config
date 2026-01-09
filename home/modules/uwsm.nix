{
	config,
	lib,
	pkgs,
	inputs,
	hm,
	...
}: let
	cfg = config.programs.uwsm;
in {
	options.programs.uwsm = {
		environment =
			lib.mkOption {
				type = with lib.types;
					lazyAttrsOf (oneOf [
							str
							path
							int
							float
						]);
				default = {};
			};
	};

	config = {
		xdg.configFile."uwsm/env".text = ''
			${inputs.home-manager.lib.hm.shell.exportAll cfg.environment}
		'';
	};
}
