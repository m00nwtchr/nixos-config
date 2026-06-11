# Port of legacy/modules/splash.nix — Plymouth dna theme + quiet boot.
{
  config,
  pkgs,
  lib,
  ...
}: {
  den.aspects.splash = {
    nixos = {
      boot.plymouth = {
        enable = lib.mkDefault true;
        theme = "dna";

        themePackages = with pkgs; [
          (adi1090x-plymouth-themes.override {
            selected_themes = ["dna"];
          })
        ];
      };

      boot.consoleLogLevel = 3;
      boot.initrd.verbose = false;
      boot.loader.timeout = 0;

      boot.kernelParams = [
        "quiet"
        "splash"
        "systemd.show_status=auto"
        "udev.log_level=3"
        "vt.global_cursor_default=0"
      ];
      boot.kernel.sysctl."kernel.printk" = "3 3 3 3";
    };
  };
}
