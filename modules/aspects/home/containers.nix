# Port of homes/x86_64-linux/m00n/containers.nix — kubectl,
# helm, k9s, etc. + podman user service.
{
  lib,
  ...
}: {
  den.aspects.home.containers = {
    homeManager = {pkgs, ...}: {
      home.packages = with pkgs; [
        kubectl
        kubelogin-oidc
        kubernetes-helm
        k9s
        cilium-cli

        k3d

        talosctl
        talhelper

        docker-compose

        lens
      ];

      services.podman = {
        enable = true;
        autoUpdate.enable = true;
      };

      systemd.user.sockets.podman = {
        Unit = {
          Description = "Podman API Socket";
          Documentation = "man:podman-system-service(1)";
        };
        Socket = {
          ListenStream = "%t/podman/podman.sock";
          SocketMode = "0660";
        };
        Install = {
          WantedBy = ["sockets.target"];
        };
      };
    };
  };
}
