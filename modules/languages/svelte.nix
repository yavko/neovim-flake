{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with builtins; let
  cfg = config.vim.languages.svelte;

  defaultServer = "svelte";
  servers = {
    svelte = {
      package = pkgs.nodePackages.svelte-language-server;
      lspConfig = ''
        lspconfig.svelte.setup {
          capabilities = capabilities;
          on_attach = attach_keymaps,
          cmd = { "${cfg.lsp.package}/bin/svelteserver", "--stdio" }
        }
      '';
    };
  };

  # TODO: specify packages
  defaultFormat = "prettier";
  formats = {
    prettier = {
      package = pkgs.nodePackages.prettier;
      nullConfig = ''
        table.insert(
          ls_sources,
          null_ls.builtins.formatting.prettier.with({
            command = "${cfg.format.package}/bin/prettier",
          })
        )
      '';
    };
  };

  # TODO: specify packages
  defaultDiagnostics = ["eslint_d"];
  diagnostics = {
    eslint_d = {
      package = pkgs.nodePackages.eslint_d;
      nullConfig = pkg: ''
        table.insert(
          ls_sources,
          null_ls.builtins.diagnostics.eslint_d.with({
            command = "${lib.getExe pkg}",
          })
        )
      '';
    };
  };
in {
  options.vim.languages.svelte = {
    enable = mkEnableOption "Svelte language support";

    treesitter = {
      enable = mkEnableOption "Enable Svelte treesitter" // {default = config.vim.languages.enableTreesitter;};

      sveltePackage = nvim.types.mkGrammarOption pkgs "svelte";
    };

    lsp = {
      enable = mkEnableOption "Enable Svelte LSP support" // {default = config.vim.languages.enableLSP;};

      server = mkOption {
        description = "Svelte LSP server to use";
        type = with types; enum (attrNames servers);
        default = defaultServer;
      };

      package = mkOption {
        description = "Svelte LSP server package";
        type = types.package;
        default = servers.${cfg.lsp.server}.package;
      };
    };

    format = {
      enable = mkEnableOption "Enable Svelte formatting" // {default = config.vim.languages.enableFormat;};

      type = mkOption {
        description = "Svelte formatter to use";
        type = with types; enum (attrNames formats);
        default = defaultFormat;
      };

      package = mkOption {
        description = "Svelte formatter package";
        type = types.package;
        default = formats.${cfg.format.type}.package;
      };
    };

    extraDiagnostics = {
      enable = mkEnableOption "Enable extra Svelte diagnostics" // {default = config.vim.languages.enableExtraDiagnostics;};

      types = lib.nvim.types.diagnostics {
        langDesc = "Svelte";
        inherit diagnostics;
        inherit defaultDiagnostics;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.treesitter.enable {
      vim.treesitter.enable = true;
      vim.treesitter.grammars = [cfg.treesitter.sveltePackage];
    })

    (mkIf cfg.lsp.enable {
      vim.lsp.lspconfig.enable = true;
      vim.lsp.lspconfig.sources.svelte-lsp = servers.${cfg.lsp.server}.lspConfig;
    })

    (mkIf cfg.format.enable {
      vim.lsp.null-ls.enable = true;
      vim.lsp.null-ls.sources.svelte-format = formats.${cfg.format.type}.nullConfig;
    })

    (mkIf cfg.extraDiagnostics.enable {
      vim.lsp.null-ls.enable = true;
      vim.lsp.null-ls.sources = lib.nvim.languages.diagnosticsToLua {
        lang = "svelte";
        config = cfg.extraDiagnostics.types;
        inherit diagnostics;
      };
    })
  ]);
}
