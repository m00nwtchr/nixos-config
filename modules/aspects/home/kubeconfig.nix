{
  den,
  lib,
  ...
}: {
  den.aspects.home.kubeconfig = {
    homeManager = {
      config,
      pkgs,
      ...
    }: let
      cfg = config.m00n.kubeconfig;
      yaml = pkgs.formats.yaml {};
    in {
      options = {
        m00n.kubeconfig = {
          enable = lib.mkEnableOption "";

          clusters = lib.mkOption {
            type = lib.types.attrsOf yaml.type;
            default = {};
          };

          contexts = lib.mkOption {
            type = lib.types.attrsOf yaml.type;
            default = {};
          };

          users = lib.mkOption {
            type = lib.types.attrsOf yaml.type;
            default = {};
          };

          config = lib.mkOption {
            type = yaml.type;
            default = {
              apiVersion = "v1";
              kind = "Config";
              current-context = "default";
            };
          };
        };
      };

      config = lib.mkIf cfg.enable {
        xdg.configFile."kube/config".source = let
          kubeconfig =
            {
              clusters =
                lib.mapAttrsToList (name: value: {
                  inherit name;
                  cluster = value;
                })
                cfg.clusters;
              contexts =
                lib.mapAttrsToList (name: value: {
                  inherit name;
                  context = value;
                })
                cfg.contexts;
              users =
                lib.mapAttrsToList (name: value: {
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
    };
  };
}
