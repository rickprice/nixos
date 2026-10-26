{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    initLua = (builtins.readFile ../../nvim/init.lua) + ''

      -- ── nvim-lilypond-suite ───────────────────────────────────────────────────
      require("nvls").setup({
        lilypond = {
          options = {
            pdf_viewer = "zathura",
          },
        },
        player = {
          options = {
            midi_synth       = "fluidsynth",
            audio_format     = "mp3",
            fluidsynth_flags = { "${pkgs.soundfont-fluid}/share/soundfonts/FluidR3_GM2-2.sf2" },
          },
        },
      })
    '';
    plugins = with pkgs.vimPlugins; [
      # Completion
      blink-cmp
      friendly-snippets

      # Colorscheme
      nightfox-nvim

      # File types
      csv-vim

      # Formatting
      conform-nvim

      # Git
      gitsigns-nvim
      neogit
      diffview-nvim

      # Navigation
      hop-nvim
      telescope-nvim

      # Marks
      marks-nvim

      # LSP
      mason-nvim
      nvim-lspconfig
      typescript-tools-nvim

      # Treesitter with grammars
      (nvim-treesitter.withPlugins (
        p: with p; [
          bash
          typescript
          tsx
          javascript
          json
          html
          css
          scss
          lua
          markdown
          markdown_inline
          python
          regex
          vim
          yaml
          rust
          haskell
        ]
      ))

      # UI / diagnostics
      noice-nvim
      nui-nvim # required by noice
      nvim-notify # required by noice
      nvim-web-devicons # icons for telescope, trouble, etc.
      rainbow-delimiters-nvim
      symbols-outline-nvim
      todo-comments-nvim
      trouble-nvim
      which-key-nvim
      snacks-nvim # terminal + zen (replaces toggleterm-nvim/zen-mode-nvim)

      # Editing
      nvim-autopairs
      vim-fetch

      # AI
      claudecode-nvim

      # Debugging
      nvim-dap
      nvim-dap-ui
      nvim-nio

      # Notes
      obsidian-nvim

      # LilyPond
      nvim-lilypond-suite

      # Shared dependencies
      plenary-nvim
    ];
  };
}
