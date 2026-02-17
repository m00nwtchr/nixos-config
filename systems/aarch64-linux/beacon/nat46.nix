{
  config,
  lib,
  pkgs,
  ...
}:

let
  # OCI instance private IPv4 (destination after OCI's edge NAT)
  privateV4 = "10.0.0.3";

  # Your real IPv6 service address (the one you want IPv4 clients to reach)
  serviceV6 = "2a02:a313:43e4:7080::7dc5";

  # Prefix used to embed IPv4 client addresses into IPv6 (for "preserved IPs")
  pool6 = "fd46:8c2f:6b91:ffff::/96";
in
{
  networking.jool.enable = true;

  # Stateless translation (SIIT / "NAT46-ish")
  networking.jool.siit.default = {
    global.pool6 = pool6;
    eamt = [
      {
        "ipv4 prefix" = privateV4;
        "ipv6 prefix" = "${serviceV6}/128";
      }
    ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;

    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
  };

  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 1;
        to = 65535;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1;
        to = 65535;
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    jool-cli
  ];
}
