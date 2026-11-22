{
  den,
  hardware,
  lib,
  ...
}: {
  hardware.mindrove = {
    nixos = {config, ...}: {
      # systemd.network.links."00-syncbox" = {
      #   matchConfig.PermanentMACAddress = "9e:dc:bc:49:9e:b2";
      #   linkConfig.Name = "syncbox0";
      # };
    };
  };
}
