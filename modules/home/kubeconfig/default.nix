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
    config = mkOption {
      type = with types; attrsOf yaml.type;
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."kube/config".source = yaml.generate "kubeconfig.yaml" cfg.config;

    home.sessionVariables = {
      KUBECONFIG = "${config.xdg.configHome}/kube/config";
      KUBECACHEDIR = "${config.xdg.cacheHome}/kube";
    };
  };
}
