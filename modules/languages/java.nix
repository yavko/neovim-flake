{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with builtins; let
  cfg = config.vim.languages.java;
in {
  options.vim.languages.java = {
    enable = mkEnableOption "Java language support";

    treesitter = {
      enable = mkEnableOption "Enable Java treesitter" // {default = config.vim.languages.enableTreesitter;};
      package = nvim.types.mkGrammarOption pkgs "java";
    };

    lsp = {
      enable = mkEnableOption "Java LSP support (java-language-server)" // {default = config.vim.languages.enableLSP;};

      package = mkOption {
        description = "java language server";
        type = types.package;
        default = pkgs.jdt-language-server;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.lsp.enable {
      vim.lsp.lspconfig.enable = true;
      vim.lsp.lspconfig.sources.jdtls = ''
        lspconfig.jdtls.setup {
          cmd = {"${cfg.lsp.package}/bin/jdt-language-server", "-data", vim.fn.stdpath("cache").."/jdtls/workspace"},
        }
      '';
    })

    (mkIf cfg.treesitter.enable {
      vim.treesitter.enable = true;
      vim.treesitter.grammars = [cfg.treesitter.package];
    })
  ]);
}
