# Port of homes/x86_64-linux/m00n/rclone.nix — rclone with
# protondrive remote (sops-fed password). Disabled by default
# (source has enable = false).
{ ... }: {
  den.aspects.home.rclone = {
    homeManager = {pkgs, ...}: {
      programs.rclone.enable = false;
    };
  };
}
