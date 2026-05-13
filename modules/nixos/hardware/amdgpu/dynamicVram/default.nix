{
  lib,
  config,
  ...
}: let
  cfg = config.hardware.amdgpu.dynamicVram;
  pagesFromGiB = gib: let
    mb = gib * 1024;
    bytes = mb * 1024 * 1024;
  in
    builtins.div bytes 4096;
in {
  options.hardware.amdgpu.dynamicVram = {
    enable = lib.mkEnableOption "AMD dynamic VRAM tuning via TTM/amdgpu kernel params";

    vramGiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      example = 24;
      description = "Target dynamically allocated VRAM limit in GiB (used to derive ttm.pages_limit/page_pool_size).";
    };

    setGttSize = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to set amdgpu.gttsize (in MiB) to match vramGiB.";
    };
  };

  config = lib.mkIf cfg.enable (
    let
      vramGiB = cfg.vramGiB;
      mb = vramGiB * 1024;
      pages = pagesFromGiB vramGiB;
      params =
        [
          "ttm.pages_limit=${toString pages}"
          "ttm.page_pool_size=${toString pages}"
        ]
        ++ lib.optional cfg.setGttSize "amdgpu.gttsize=${toString mb}";
    in {
      boot.kernelParams = lib.mkAfter params;
    }
  );
}
