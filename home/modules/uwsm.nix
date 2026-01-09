{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.programs.uwsm = {
    environment = lib.mkOption {
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
      ${inputs.home-manager.lib.hm.shell.exportAll config.programs.uwsm.environment}
    '';
  };
}
