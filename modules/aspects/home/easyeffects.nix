{
  den,
  lib,
  inputs,
  ...
}: {
  den.aspects.home.easyeffects = {
    homeManager = {config, ...}: let
      presetsPath = "${inputs.self}/hosts/tide/easyeffects";

      entries =
        if builtins.pathExists presetsPath
        then builtins.readDir presetsPath
        else {};
      presetFiles =
        lib.filterAttrs
        (name: type: type == "regular" && lib.hasSuffix ".json" name)
        entries;
      presets =
        lib.mapAttrs'
        (
          name: _: let
            key = lib.removeSuffix ".json" name;
            path = presetsPath + "/${name}";
          in
            lib.nameValuePair key (builtins.fromJSON (builtins.readFile path))
        )
        presetFiles;

      presetNames = builtins.attrNames presets;
      preset =
        if builtins.length presetNames == 1
        then builtins.head presetNames
        else null;
    in {
      services.easyeffects = {
        enable = true;
        extraPresets = presets;
        preset = lib.mkIf (preset != null) preset;
      };
    };
  };
}
