{
  lib,
  pkgs,
  inputs,
  system,
  namespace,
  osConfig,
  ...
}:
with lib; let
  presetsPath = "${inputs.self}/systems/${system}/${osConfig.networking.hostName}/easyeffects";

  entries =
    if builtins.pathExists presetsPath
    then builtins.readDir presetsPath
    else {};
  presetFiles =
    lib.filterAttrs
    (name: type: type == "regular" && hasSuffix ".json" name)
    entries;
  presets =
    mapAttrs'
    (
      name: _: let
        key = removeSuffix ".json" name;
        path = presetsPath + "/${name}";
      in
        nameValuePair key (builtins.fromJSON (builtins.readFile path))
    )
    presetFiles;

  presetNames = attrNames presets;
  preset =
    if builtins.length presetNames == 1
    then builtins.head presetNames
    else null;
in {
  services.easyeffects = {
    enable = true;
    extraPresets = presets;
    preset = mkIf (preset != null) preset;
  };
}
