{
  config,
  lib,
  pkgs,
  inputs,
  system,
  osConfig,
  ...
}: {
  home.packages = with pkgs; [
    # Kubernetes
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
    settings.storage.storage.driver = lib.mkForce osConfig.virtualisation.containers.storage.settings.storage.driver;
  };

  systemd.user.sockets.podman = {
    Unit = {
      Description = "Podman API Socket";
      Documentation = "man:podman-system-service(1)";
    };
    Socket = {
      ListenStream = "%t/podman/podman.sock";
      SocketMode = 0660;
    };
    Install = {
      WantedBy = ["sockets.target"];
    };
  };
}
