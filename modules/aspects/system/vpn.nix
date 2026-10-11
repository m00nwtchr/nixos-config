{
  den,
  lib,
  inputs,
  ...
}: {
  den.aspects.system.vpn = {host}: {
    nixos = {
      config,
      pkgs,
      ...
    }: let
      secretsDir = "${inputs.self}/hosts/${host.name}/secrets/wg";

      files =
        if builtins.pathExists secretsDir
        then
          lib.filterAttrs
          (
            name: type:
              type == "regular" && lib.hasSuffix ".yaml" name
          )
          (builtins.readDir secretsDir)
        else {};

      names = map (lib.removeSuffix ".yaml") (builtins.attrNames files);

      parseYaml = file:
        builtins.fromJSON (builtins.readFile (
          pkgs.runCommand "wg-config.json" {
            nativeBuildInputs = [pkgs.yq-go];
          } ''
            yq -o=json '.' ${file} > "$out"
          ''
        ));

      tunnels = lib.genAttrs names (
        name:
          parseYaml (secretsDir + "/${name}.yaml")
      );

      secretFile = name:
        secretsDir + "/${name}.yaml";

      secretName = name: "wg-${name}-privateKey";

      interfaceName = name: "${name}";
    in {
      networking.useNetworkd = true;
      systemd.network.enable = true;

      sops.secrets = lib.mkMerge (
        map (name: {
          "wg-${name}-privateKey" = {
            sopsFile = secretFile name;
            key = "interface/privateKey";
            group = "systemd-network";
            mode = "0640";
          };

          "wg-${name}-publicKey" = {
            sopsFile = secretFile name;
            key = "peer/publicKey";
            group = "systemd-network";
            mode = "0640";
          };
        })
        names
      );

      systemd.network.netdevs =
        lib.mapAttrs' (
          name: tunnel: let
            peer = tunnel.peer;
          in
            lib.nameValuePair "50-${interfaceName name}" {
              netdevConfig = {
                Kind = "wireguard";
                Name = interfaceName name;
              };

              wireguardConfig = {
                PrivateKeyFile =
                  config.sops.secrets.${secretName name}.path;

                RouteTable = "main";
              };

              wireguardPeers = [
                ({
                    PublicKeyFile =
                      config.sops.secrets."wg-${name}-publicKey".path;
                    Endpoint = peer.endpoint;
                    AllowedIPs = peer.allowedIPs or [];
                  }
                  // lib.optionalAttrs (peer ? persistentKeepalive) {
                    PersistentKeepalive = peer.persistentKeepalive;
                  })
              ];
            }
        )
        tunnels;

      systemd.network.networks =
        lib.mapAttrs' (
          name: tunnel:
            lib.nameValuePair "50-${interfaceName name}" {
              matchConfig.Name = interfaceName name;

              address = tunnel.interface.address;
              dns = tunnel.interface.dns or [];

              linkConfig.RequiredForOnline = "no";
            }
        )
        tunnels;
    };
  };
}
