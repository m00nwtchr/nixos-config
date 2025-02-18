{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
  ];

  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    prismlauncher
    lutris
  ];

  services = {
  };
}
