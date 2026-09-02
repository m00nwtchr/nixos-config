# Port of homes/x86_64-linux/m00n/dev.nix — helix+langservers, git
# signing config, uv, dev tooling. Imports the rust + containers
# sub-aspects of the home.
{
  den,
  lib,
  inputs,
  __findFile ? __findFile,
  ...
}: {
  flake-file.inputs.mcp-nixos = {
    url = "github:utensils/mcp-nixos";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-parts.follows = "flake-parts";
  };

  den.aspects.opencode-vm = {
    includes = [den.aspects.ai];

    nixos = {
      microvm.hypervisor = "cloud-hypervisor";
      microvm.vsock.cid = 42;
    };
    microvm.autostart = false;
  };

  den.aspects.ai = {
    homeManager = {
      pkgs,
      inputs',
      ...
    }: {
      home.packages = with pkgs; [
      ];

      programs.mcp = {
        enable = true;
        servers = {
          "m00nlit.dev" = {
            enabled = false;
            url = "https://mcp.m00nlit.dev";
          };
          context7.url = "https://mcp.context7.com/mcp";
          nixos.command = "${lib.getExe inputs'.mcp-nixos.packages.default}";
          devenv = {
            command = lib.getExe pkgs.devenv;
            args = ["mcp"];
          };
          zotero = {
            enabled = false;
            command = "zotero-mcp";
            env.ZOTERO_LOCAL = "true";
          };
          fluxcd = {
            enabled = false;
            command = lib.getExe pkgs.fluxcd-operator-mcp;
            args = ["serve"];
          };
          codebase-memory-mcp.command = "/home/m00n/.local/bin/codebase-memory-mcp";
        };
      };

      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
        tui = {
          plugin = ["@honcho-ai/opencode-honcho"];
        };
        settings = {
          plugin = ["superpowers@git+https://github.com/obra/superpowers.git#v6.3.0"];

          provider.lmstudio = {
            name = "LM Studio";
            npm = "@ai-sdk/openai-compatible";
            options.baseURL = "http://127.0.0.1:1234/v1";
            models = {
              "qwen/qwen3.6-35b-a3b".name = "Qwen3.6 35B A3B";
              "qwen3.8:27b".name = "Qwen3.8 27B";
            };
          };
          # provider.llama-server = {
          #   name = "llama-server";
          #   npm = "@ai-sdk/openai-compatible";
          #   options.baseURL = "http://127.0.0.1:9931/v1";
          #   models = {
          #     "qwen3.8:27b".name = "Qwen3.8 27B";
          #   };
          # };

          permission = {
            external_directory = {
              "~/.local/share/cargo/registry/**" = "allow";
              "/nix/store/**" = "deny";
            };
            edit = {
              "~/.local/share/cargo/registry/**" = "deny";
              "/nix/store/**" = "deny";
            };
          };

          # Default outside of explicitly selected agents.
          model = "openai/gpt-5.6-luna";

          agent = {
            coordinator = {
              description = "Reasoning coordinator — plans, then delegates to role subagents (explorer/fixer/fixer-bigctx/oracle/reviewer)";
              mode = "primary";
              model = "openai/gpt-5.6-luna";
              reasoningEffort = "xhigh";

              prompt = ''
                You are a coordinator. Do the high-level reasoning and synthesis yourself; delegate the legwork to role subagents via the task tool.

                CONTRACTS: hand each sub a self-contained brief — objective, the decisions already settled (inline the exact values), the files it owns, what's out of scope, and the observable check that proves success. A sub should never have to infer scope or re-derive a decision you already made. Ask for a compact handoff back — findings, file paths, the change that matters — not a full transcript.

                ROLES:
                - `explorer` (MiniMax M3): default recon, read-only scouting, "where/how is X". It is the main concurrency lane, so fan out here.
                - `fixer` (OpenAI): small scoped implementation and edits. Keep its jobs small and bounded.
                - `fixer-bigctx` (MiniMax M3): bulk/context-heavy coding lane. Use when a task benefits from very large context.
                - `oracle` (GPT-5.6 Luna Max): hard debugging, root-cause analysis, architecture, and difficult reasoning. Expensive/high-compute, so don't use it as the default lane.
                - `reviewer` (MiniMax M3): independent second opinion, review, and prose.

                COUNCIL (high-stakes review): collect independent verdicts from different model/configuration lanes — MiniMax (`explorer`/`reviewer`) and OpenAI (`fixer`/`oracle`) — then reconcile. Never let one model grade its own work.
              '';
            };

            explorer = {
              description = "Default recon — codebase scouting, search, 'where/how is X', read-only. MiniMax M3 with very large context; preferred concurrency lane.";
              mode = "subagent";
              model = "minimax/MiniMax-M3";
            };

            fixer = {
              description = "Fast scoped implementation — OpenAI coding/reasoning model. Use for bounded edits and implementation tasks.";
              mode = "subagent";
              model = "openai/gpt-5.6-luna";
            };

            fixer-bigctx = {
              description = "Bulk and context-heavy coding lane — MiniMax M3. Prefer for repository-wide work and tasks requiring very large context.";
              mode = "subagent";
              model = "minimax/MiniMax-M3";
            };

            oracle = {
              description = "Hard debugging / architecture / root-cause analysis — GPT-5.6 Luna at maximum reasoning. Read-mostly deep analysis; return a recommendation rather than sprawling into edits.";
              mode = "subagent";
              model = "openai/gpt-5.6-luna";
              reasoningEffort = "max";
            };

            reviewer = {
              description = "Independent review and second opinion — MiniMax M3. Prefer for reviewing OpenAI-produced implementation so the author does not grade its own work.";
              mode = "subagent";
              model = "minimax/MiniMax-M3";
            };
          };
        };
      };
    };
  };
}
