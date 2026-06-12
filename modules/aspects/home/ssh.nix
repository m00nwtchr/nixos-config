# Port of homes/x86_64-linux/m00n/ssh.nix — ssh-tpm-agent +
# ControlMaster settings + per-host entries for ganymede/beacon.
{
  config,
  pkgs,
  ...
}: {
  den.aspects.home.ssh = {
    homeManager = {pkgs, config, ...}: {
      home.packages = with pkgs; [
        ssh-tpm-agent
      ];

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            AddKeysToAgent = "yes";
            Compression = false;
            ControlMaster = "auto";
            ControlPath = "\${XDG_RUNTIME_DIR}/ssh/socket-%C";
            ControlPersist = "60";
            ServerAliveInterval = 15;
            ServerAliveCountMax = 3;
            ForwardAgent = false;
            UserKnownHostsFile = "${config.xdg.stateHome}/ssh/known_hosts";
          };
        };
      };

      services.ssh-agent.enable = true;

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
          SocketMode = "0600";
          Service = "ssh-tpm-agent.service";
        };
        Install = {
          WantedBy = ["sockets.target"];
        };
      };
    };
  };
}
