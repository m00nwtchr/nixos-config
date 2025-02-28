# https://search.nixos.org/options
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/efi/secureboot.nix
    ../../modules/system/k3s.nix
    ../../modules/nvidia.nix

    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.kernelPackages = pkgs.linuxPackages_hardened;
  boot.kernelParams = [
  ];

  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;

  zramSwap.enable = true;

  networking.hostName = "m00nsrv"; # Define your hostname.

  networking.hosts = {
    "2a02:a313:43e4:7080::7dc5" = ["idm.m00nlit.dev" "m00nlit.dev" "m00nsrv"];
    "192.168.0.10" = ["m00nlit.dev" "m00nsrv"];
  };

  networking.firewall = {
    allowedTCPPorts = [25565 443 80];
    allowedUDPPorts = [25565 443];
  };

  systemd.network.networks."20-wired" = {
    name = "enp4s0";

    DHCP = "no";

    networkConfig = {
      IPv6AcceptRA = "yes";
      IPv6PrivacyExtensions = "yes";
      MulticastDNS = "yes";
    };

    address = ["192.168.0.10/24"];
    gateway = ["192.168.0.1"];

    ipv6AcceptRAConfig = {
      Token = "prefixstable";
      UseDNS = "no";
    };
  };

  # Gitea
  users.groups.git = {};
  users.users.git = let
    giteaShell = pkgs.writeShellScriptBin "gitea-shell" ''
      exec ${pkgs.kubectl}/bin/kubectl --client-certificate=/var/lib/git/git.crt --client-key=/var/lib/git/git.key --certificate-authority=/var/lib/git/server-ca.crt -s "https://localhost:6443" -n gitea exec -i deployment/forgejo -c forgejo -- env SSH_ORIGINAL_COMMAND="$SSH_ORIGINAL_COMMAND" sh "$@"
    '';
  in {
    group = "git";
    isSystemUser = true;
    home = "/var/lib/git";
    shell = "${giteaShell}/bin/gitea-shell";
  };
  services.openssh.extraConfig = ''
    Match User git
      AuthorizedKeysCommandUser git
      AuthorizedKeysCommand /etc/ssh/git_authorized_keys.sh -e git -u %u -t %t -k %k
  '';

  environment.etc."ssh/git_authorized_keys.sh" = {
    text = ''
      #!/bin/sh
      exec ${pkgs.kubectl}/bin/kubectl --client-certificate=/var/lib/git/git.crt --client-key=/var/lib/git/git.key --certificate-authority=/var/lib/git/server-ca.crt -s "https://localhost:6443" -n gitea exec -i deployment/forgejo -c forgejo -- /usr/local/bin/gitea keys "$@"
    '';
    mode = "0755";
    user = "root";
    group = "root";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gpg
  ];

  security.tpm2.enable = true;

  services = {
    btrfs.autoScrub = {
      enable = true;
      fileSystems = ["/" "/mnt/hdd"];
    };
    # beesd.filesystems.root = {
    #   spec = "/";
    #   hashTableSizeMB = 512;
    # };

    k3s = {
      enable = lib.mkForce true;
      role = "server";
      # serverAddr = "https://m00nsrv:6443";

      node = {
        podCIDRs = [
          "2001:cafe:42::/64"
          "10.42.0.0/24"
        ];

        ips = [
          "fd7a:115c:a1e0::f201:2d35"
          "100.116.45.53"
        ];

        externalIPs = [
          "2a02:a313:43e4:7080::7dc5"
          "192.168.0.10"
        ];
      };
    };
  };

  # virtualisation = {
  # 	containers.enable = true;
  # 	oci-containers.backend = "podman";
  # 	podman = {
  # 		enable = true;
  # 		dockerCompat = true;
  # 		defaultNetwork.settings.dns_enabled = true;
  # 	};
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
