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
  flake-file.inputs.comfyui-nix = {
    url = "github:utensils/comfyui-nix";
    inputs.flake-parts.follows = "flake-parts";
  };

  flake-file.inputs.nix-amd-ai = {
    url = "github:noamsto/nix-amd-ai";
    inputs.flake-parts.follows = "flake-parts";
  };

  flake-file.inputs.mcp-nixos = {
    url = "github:utensils/mcp-nixos";
    inputs.nixpkgs.follows = "nixpkgs"; # no binary cache
    inputs.flake-parts.follows = "flake-parts";
  };

  flake-file.inputs.codebase-memory-mcp = {
    url = "github:DeusData/codebase-memory-mcp";
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
    provides.to-hosts = {host, ...}: {
      nixos = {
        config,
        pkgs,
        ...
      }: {
        imports = [inputs.nix-amd-ai.nixosModules.default];
        nixpkgs.overlays = [inputs.comfyui-nix.overlays.default];

        hardware.amd-npu = {
          enable = true;
          enableFastFlowLM = true; # LLM inference on NPU (requires enableNPU)
          enableLemonade = true; # OpenAI-compatible API server
          enableROCm = false; # ROCm GPU backends (llamacpp + sd-cpp)
          enableVulkan = true; # Vulkan GPU backends (llamacpp + whispercpp)
          enableImageGen = false; # default true; set false to drop sd-cpp from closure
          lemonade.user = "m00n";
        };
        users.users.m00n.extraGroups = ["render"];

        environment.systemPackages = with pkgs; [
          onnxruntime
          llama-cpp-vulkan
        ];

        sops.secrets."context7_api_key" = {
          sopsFile = toString "${inputs.self}/secrets/mcp.yaml";
          owner = config.users.users.m00n.name;
          group = config.users.users.m00n.group;
        };

        sops.secrets."memini_api_key" = {
          sopsFile = toString "${inputs.self}/secrets/mcp.yaml";
          owner = config.users.users.m00n.name;
          group = config.users.users.m00n.group;
        };
      };
    };

    homeManager = {
      config,
      osConfig,
      pkgs,
      inputs',
      ...
    }: let
      codebase-memory-mcp = pkgs.codebase-memory-mcp;
      # codebase-memory-mcp = inputs'.codebase-memory-mcp.packages.default;
    in {
      home.packages = [
        # codebase-memory-mcp
        # inputs'.letta-code.packages.default

        # pkgs.comfy-ui-rocm
      ];

      programs.zsh.envExtra = ''
        export CONTEXT7_API_KEY="$(cat ${osConfig.sops.secrets."context7_api_key".path})"
        export MEMINI_API_KEY="$(cat ${osConfig.sops.secrets."memini_api_key".path})"
      '';

      programs.mcp = {
        enable = true;
        servers = {
          "naktis.eu" = {
            enabled = false;
            url = "https://mcp.naktis.eu/mcp";
          };
          "kguardian" = {
            enabled = false;
            url = "http://localhost:8080/mcp";
            headers.Authorization = "Bearer {env:KGUARDIAN_TOKEN}";
          };
          "somatic" = {
            enabled = false;
            url = "http://localhost:8080/mcp";
            headers.Authorization = "Bearer {env:SOMATIC_TOKEN}";
          };
          context7 = {
            url = "https://mcp.context7.com/mcp";
            headers.Authorization = "Bearer {env:CONTEXT7_API_KEY}";
          };
          nixos.command = "${lib.getExe inputs'.mcp-nixos.packages.default}";
          devenv = {
            command = lib.getExe pkgs.devenv;
            args = ["mcp"];
          };
          zotero = {
            enabled = false;
            command = lib.getExe pkgs.podman;
            args = [
              "--rm"
              "-it"
              "-v"
              "${config.xdg.configHome}/zotero-mcp:/home/app/.config/zotero-mcp"
              "-e"
              "ZOTERO_LOCAL=true"
              "ghcr.io/54yyyu/zotero-mcp:latest"
            ];
            # env.ZOTERO_LOCAL = "true";
          };
          fluxcd = {
            enabled = false;
            command = lib.getExe pkgs.fluxcd-operator-mcp;
            args = ["serve"];
          };
          codebase-memory-mcp.command = lib.getExe codebase-memory-mcp;
        };
      };

      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
        tui = {
          # plugin = ["@honcho-ai/opencode-honcho"];
        };
        settings = {
          plugin = [
            # "superpowers@git+https://github.com/obra/superpowers.git#v7.0.0"
            # [
            #   "@eleboucher/opencode-memini"
            #   {
            #     base_url = "https://memini.naktis.eu";
            #   }
            # ]
          ];

          provider.kepler = {
            name = "Kepler";
            npm = "@ai-sdk/openai-compatible";
            options.baseURL = "https://kepler.tail096cd8.ts.net:9931/v1";
            models = {
              "lfm3:1.7b".name = "LFM3 1.7B";
            };
          };

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
                - `reviewer-openai` (GPT-5.6 Luna): independent review of MiniMax-produced work.

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
            reviewer-openai = {
              description = "Independent review of MiniMax-produced work — OpenAI reasoning model. Do not use to review OpenAI-produced work.";
              mode = "subagent";
              model = "openai/gpt-5.6-luna";
            };
          };
        };

        context = ''
          <!-- codebase-memory-mcp:start -->
          # Codebase Knowledge Graph (codebase-memory-mcp)

          This project uses codebase-memory-mcp to maintain a knowledge graph of the codebase.
          ALWAYS prefer MCP graph tools over grep/glob/file-search for code discovery.

          ## Priority Order
          1. `search_graph` — find functions, classes, routes, variables by pattern
          2. `trace_path` — trace who calls a function or what it calls
          3. `get_code_snippet` — read specific function/class source code
          4. `query_graph` — run Cypher queries for complex patterns
          5. `get_architecture` — high-level project summary

          ## When to fall back to grep/glob
          - Searching for string literals, error messages, config values
          - Searching non-code files (Dockerfiles, shell scripts, configs)
          - When MCP tools return insufficient results

          ## Examples
          - Find a handler: `search_graph(name_pattern=".*OrderHandler.*")`
          - Who calls it: `trace_path(function_name="OrderHandler", direction="inbound")`
          - Read source: `get_code_snippet(qualified_name="pkg/orders.OrderHandler")`
          <!-- codebase-memory-mcp:end -->

          ## GPG fail-stop
          If any GPG operation fails—including commit/tag signing—stop immediately. Do not retry, bypass signing, use an alternate signing method, or continue with related actions; report the failure and wait for explicit human instructions.
        '';
      };
    };
  };
}
