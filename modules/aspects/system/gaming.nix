# Port of legacy/modules/gaming.nix — Steam, gamemode, gamescope,
# wine-staging, etc.
{
  config,
  pkgs,
  lib,
  ...
}: {
  den.aspects.system.gaming = {
    nixos = {
      config,
      pkgs,
      ...
    }: {
      hardware.graphics.enable32Bit = true;

      programs.steam = {
        enable = true;
        package = pkgs.steam;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;

        protontricks.enable = true;
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

      environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      };
    };

    provides.to-users.homeManager = {
      pkgs,
      osConfig,
      ...
    }: {
      xdg.autostart.entries = [
        "${osConfig.programs.steam.package}/share/applications/steam.desktop"
      ];

      home.packages = with pkgs; [
        mangohud
        protonup-ng

        heroic

        wineWow64Packages.staging
        winetricks

        pcsx2
      ];

      programs.prismlauncher = {
        enable = true;
        settings.JavaPath = lib.getExe pkgs.openjdk25;
        settings.IconTheme = "pe_dark";
      };

      programs.lutris = {
        enable = true;
        protonPackages = with pkgs; [
          proton-ge-bin
        ];
        defaultWinePackage = pkgs.proton-ge-bin;
        steamPackage = osConfig.programs.steam.package;
      };
    };
  };
}
