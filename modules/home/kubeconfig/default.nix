{
	lib,
	pkgs,
	namespace,
	config,
	...
}:
with lib; let
	cfg = config.${namespace}.kubeconfig;
	yaml = pkgs.formats.yaml {};
in {
	options.${namespace}.kubeconfig = with lib.options; {
		enable = mkEnableOption "";

		clusters =
			mkOption {
				type = with types; attrsOf yaml.type;
			};
		contexts =
			mkOption {
				type = with types; attrsOf yaml.type;
			};
		users =
			mkOption {
				type = with types; attrsOf yaml.type;
			};

		config =
			mkOption {
				type = yaml.type;
				default = {
					apiVersion = "v1";
					kind = "Config";
					current-context = "default";
				};
			};
	};

	config =
		mkIf cfg.enable {
			xdg.configFile."kube/config".source = let
				kubeconfig =
					{
						clusters =
							attrsets.mapAttrsToList (name: value: {
									inherit name;
									cluster = value;
								})
							cfg.clusters;
						contexts =
							attrsets.mapAttrsToList (name: value: {
									inherit name;
									context = value;
								})
							cfg.contexts;
						users =
							attrsets.mapAttrsToList (name: value: {
									inherit name;
									user = value;
								})
							cfg.users;
					}
					// cfg.config;
			in
				yaml.generate "kubeconfig.yaml" kubeconfig;

			home.sessionVariables = {
				KUBECONFIG = "${config.xdg.configHome}/kube/config";
				KUBECACHEDIR = "${config.xdg.cacheHome}/kube";
			};
		};
}
