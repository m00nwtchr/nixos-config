# Port of homes/x86_64-linux/m00n/wallust/default.nix — wallust
# theme generator. Installs the wallust.toml and templates directory
# as xdg.configFile entries. The wallust.toml and templates live
# in home/m00n/wallust/ (copied verbatim from source).
{...}: {
  den.aspects.home.wallust = {
    homeManager = {config, ...}: {
      xdg.configFile."wallust/wallust.toml".source = ../../../home/m00n/wallust/wallust.toml;
      xdg.configFile."wallust/templates".source = ../../../home/m00n/wallust/templates;
    };
  };
}
