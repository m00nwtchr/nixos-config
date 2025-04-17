{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
  ];

  hardware.graphics.enable32Bit = true;

  programs.steam = {
    enable = true;
    package = pkgs.steam;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers

    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.java.enable = true;

  environment.systemPackages = with pkgs; [
    prismlauncher
    lutris
    heroic
  ];

  services = {
  };
}
