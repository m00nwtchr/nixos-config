# Port of legacy/modules/gaming.nix — Steam, gamemode, gamescope,
# wine-staging, etc.
{
  config,
  pkgs,
  lib,
  ...
}: {
  den.aspects.gaming = {
    nixos = {
      hardware.graphics.enable32Bit = true;

      programs.steam = {
        enable = true;
        package = pkgs.steam;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;

        gamescopeSession.enable = true;
      };

      programs.gamemode = {
        enable = true;

        settings = {
          general = {
            desiredgov = "performance";
            desiredprof = "performance";

            renice = 10;
            ioprio = 0;
          };

          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            # nv_powermizer_mode = lib.mkIf detected.nvidia 1;
          };
        };
      };
      users.users.m00n.extraGroups = ["gamemode"];

      programs.gamescope = {
        enable = true;
        capSysNice = true;
      };

      programs.java.enable = true;

      environment.systemPackages = with pkgs; [
        mangohud
        protonup-ng

        prismlauncher
        heroic

        wineWow64Packages.staging
        winetricks
      ];

      environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      };
    };
  };
}
