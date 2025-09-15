{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    ssh-tpm-agent
  ];

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        compression = false;
        controlMaster = "auto";
        controlPath = "\${XDG_RUNTIME_DIR}/ssh/socket-%C";
        controlPersist = "60";
        serverAliveInterval = 15;
        serverAliveCountMax = 3;
      };

      m00nsrv = {
        host = "m00nsrv";
        user = "root";
        extraOptions = {
          RemoteForward = "/run/user/0/gnupg/S.gpg-agent /run/user/1000/gnupg/d.qdacfuwqbr7ghuh8iphysdf9/S.gpg-agent.extra";
        };
      };
      bastion = {
        host = "bastion";
        user = "root";
        extraOptions = {
          RemoteForward = "/run/user/0/gnupg/S.gpg-agent /run/user/1000/gnupg/d.qdacfuwqbr7ghuh8iphysdf9/S.gpg-agent.extra";
        };
      };
    };
  };

  services = {
    ssh-agent.enable = true;
  };

  systemd.user.services.ensure-ssh-dir = {
    Unit.Description = "Ensure $XDG_RUNTIME_DIR/ssh exists";
    Service.ExecStart = "${pkgs.coreutils}/bin/mkdir -p %t/ssh";
    Service.Type = "oneshot";
    Install.WantedBy = ["default.target"];
  };

  systemd.user.services.ssh-tpm-agent = {
    Unit = {
      ConditionEnvironment = "!SSH_AGENT_PID";
      Description = "ssh-tpm-agent service";
      Documentation = "man:ssh-agent(1) man:ssh-add(1) man:ssh(1)";
      Requires = "ssh-tpm-agent.socket";
    };
    Service = {
      Environment = "SSH_TPM_AUTH_SOCK=%t/ssh-tpm-agent.sock";
      ExecStart = "${pkgs.ssh-tpm-agent}/bin/ssh-tpm-agent";
      PassEnvironment = "SSH_AGENT_PID";
      SuccessExitStatus = 2;
      Type = "simple";
    };
    Install = {
      Also = "ssh-agent.socket";
    };
  };
  systemd.user.sockets.ssh-tpm-agent = {
    Unit = {
      Description = "SSH TPM agent socket";
      Documentation = "man:ssh-agent(1) man:ssh-add(1) man:ssh(1)";
    };
    Socket = {
      ListenStream = "%t/ssh-tpm-agent.sock";
      SocketMode = 0600;
      Service = "ssh-tpm-agent.service";
    };
    Install = {
      WantedBy = [ "sockets.target" ];
    };
  };
}
