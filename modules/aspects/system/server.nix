# Port of legacy/modules/system/server.nix — kernel/sysctl tuning,
# zram sysctls, kanidm client, smartd defaults, root's authorized
# keys. Includes <system/ssh> and <system/chrony>.
{
  __findFile ? __findFile,
  inputs,
  ...
}: {
  den.aspects.system.server = {
    includes = [
      <system/ssh>
      <system/chrony>
    ];

    nixos = {
      config,
      pkgs,
      lib,
      ...
    }: {
      boot.kernel.sysctl = {
        "net.core.somaxconn" = 1024;
        "net.core.netdev_max_backlog" = 16384;
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
        "net.ipv4.tcp_rmem" = "4096 87380 16777216";
        "net.ipv4.tcp_wmem" = "4096 65536 16777216";
        "net.ipv4.tcp_max_syn_backlog" = 8096;
        "net.ipv4.tcp_slow_start_after_idle" = 0;
        "net.ipv4.tcp_tw_reuse" = 1;
        "net.ipv4.tcp_fin_timeout" = 30;
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.ipv4.tcp_fastopen" = 3;

        "vm.vfs_cache_pressure" = 50;
        "vm.overcommit_memory" = 1;
        "vm.max_map_count" = 262144;
        "vm.dirty_background_ratio" = 5;
        "vm.dirty_ratio" = 15;

        "fs.file-max" = 2097152;
        "fs.inotify.max_user_instances" = 8192;
        "fs.inotify.max_user_watches" = 524288;

        "kernel.sched_autogroup_enabled" = 0;
        "kernel.sched_migration_cost_ns" = 5000000;

        "kernel.panic" = 10;
        "kernel.panic_on_oops" = 1;
      };

      environment.systemPackages = with pkgs; [
        nnn
        tpm2-tools
        ldns
      ];

      users.users.root.openssh.authorizedKeys.keyFiles = [
        (toString inputs.self + "/secrets/authorized_keys")
      ];
      services.openssh = {
        authorizedKeysCommand = "/opt/kanidm_ssh_authorizedkeys %u";
        authorizedKeysCommandUser = "nobody";
        settings.UsePAM = true;
      };

      system.activationScripts.kanidmSshAuthorizedKeys = ''
        cp ${config.services.kanidm.package}/bin/kanidm_ssh_authorizedkeys /opt/kanidm_ssh_authorizedkeys
        chown root:root /opt/kanidm_ssh_authorizedkeys
        chmod 0755 /opt/kanidm_ssh_authorizedkeys
      '';

      services.kanidm = {
        package = pkgs.kanidm_1_10;
        client.settings = {
          uri = "https://idm.naktis.eu";
        };

        unix.enable = true;
        unix.settings = {
          version = "2";
          home_alias = "name";
          uid_attr_map = "name";
          gid_attr_map = "name";
          kanidm = {
            pam_allowed_login_groups = ["unix_admins"];
            map_group = [
              {
                local = "wheel";
                "with" = "unix_admins";
              }
            ];
          };
        };
      };

      services.smartd = {
        enable = true;
        defaults.monitored = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../7/04) -W 4,45,55 -l error -l xerror -l selftest";
      };
    };
  };
}
