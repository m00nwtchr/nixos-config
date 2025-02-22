{
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.sshTpmAgent = {
    enable = lib.mkEnableOption {
      default = config.security.tpm2.enable;
    };
    hostKeys = lib.mkEnableOption;
  };

  config = {
    services.openssh.settings =
      if config.services.sshTpmAgent.enable && config.services.sshTpmAgent.hostKeys
      then {
        HostKeyAgent = "/var/tmp/ssh-tpm-agent.sock";
        HostKey = [
          "/etc/ssh/ssh_tpm_host_ecdsa_key.pub"
          "/etc/ssh/ssh_tpm_host_rsa_key.pub"
        ];
      }
      else {};

    systemd.services."ssh-tpm-genkeys" = {
      enable = config.services.sshTpmAgent.enable && config.services.sshTpmAgent.hostKeys;
      description = "SSH TPM Key Generation";
      unitConfig = {
        ConditionPathExists = [
          "|!/etc/ssh/ssh_tpm_host_ecdsa_key.tpm"
          "|!/etc/ssh/ssh_tpm_host_ecdsa_key.pub"
          "|!/etc/ssh/ssh_tpm_host_rsa_key.tpm"
          "|!/etc/ssh/ssh_tpm_host_rsa_key.pub"
        ];
      };

      script = "${pkgs.ssh-tpm-agent}/bin/ssh-tpm-keygen -A";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
    };

    systemd.services."ssh-tpm-agent" = {
      enable = config.services.sshTpmAgent.enable && config.services.sshTpmAgent.hostKeys;
      description = "ssh-tpm-agent service";
      documentation = "man:ssh-agent(1) man:ssh-add(1) man:ssh(1)";
      wants = ["ssh-tpm-genkeys.service"];
      afters = [
        "ssh-tpm-genkeys.service"
        "network.target"
        "sshd.target"
      ];
      requires = ["ssh-tpm-agent.socket"];
      unitConfig = {
        ConditionEnvironment = "!SSH_AGENT_PID";
      };

      script = "${pkgs.ssh-tpm-agent}/bin/ssh-tpm-agent --key-dir /etc/ssh";
      serviceConfig = {
        PassEnvironment = "SSH_AGENT_PID";
        KillMode = "process";
        Restart = "always";
      };
    };

    systemd.sockets."ssh-tpm-agent" = {
      enable = config.services.sshTpmAgent.enable && config.services.sshTpmAgent.hostKeys;
      description = "SSH TPM agent socket";
      documentation = "man:ssh-agent(1) man:ssh-add(1) man:ssh(1)";
      listenStreams = ["/var/tmp/ssh-tpm-agent.sock"];
      socketConfig = ''
        SocketMode=0600
      '';
    };
  };
}
