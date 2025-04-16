{
  pkgs,
  lib,
  config,
  ...
}: let
  commonPath = "${config.dotfiles.path}/wallust";
  configSrc =
    if !config.dotfiles.mutable
    then ./wallust.toml
    else config.lib.file.mkOutOfStoreSymlink "${commonPath}/wallust.toml";

  templateSrc =
    if !config.dotfiles.mutable
    then ./templates
    else config.lib.file.mkOutOfStoreSymlink "${commonPath}/templates";
in {
  xdg.configFile."wallust/wallust.toml".source = configSrc;
  xdg.configFile."wallust/templates".source = templateSrc;
}
