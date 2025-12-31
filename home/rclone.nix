{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.rclone = {
    enable = true;
    remotes = {
    };
  };
}
