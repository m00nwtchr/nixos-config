# Port of homes/x86_64-linux/m00n/modules/dotfiles.nix — declares
# the `dotfiles.path` option used by sway.nix. The source uses
# `${config.home.homeDirectory}/nixos-config/home` as the path.
# In den we don't have a `dotfiles` option anymore (removed in
# current home-manager), so this is a no-op stub kept for parity
# with the source layout.
{ ... }: {
  den.aspects.home.modules-dotfiles = {
    homeManager = {config, ...}: {
      # Source equivalent:
      #   options.dotfiles.path = "${config.home.homeDirectory}/nixos-config/home";
    };
  };
}
