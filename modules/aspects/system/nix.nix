{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  den.aspects.nix = {
    nixos = {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        use-xdg-base-directories = true;
        download-buffer-size = 524288000; # 500 MiB
        accept-flake-config = true;
        trusted-users = ["m00n"];
        trusted-substituters = [
          "https://nix-community.cachix.org"
          "https://numtide.cachix.org"
          "https://attic.m00nlit.dev/m00n"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          "m00n:kbAQdFU/e4Vec5EnGwobPlNJ98r33SMjwkuWLV/h7lo="
        ];
      };

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 7d --keep 3 --optimise";
        flake = "/etc/nixos";
      };

      environment.etc."current-nixos".source = "${inputs.self}";
    };
  };
}
