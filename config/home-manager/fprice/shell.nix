{
  pkgs,
  osConfig,
  ...
}:

{
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        ls = "eza";
        ll = "eza -la";
        lt = "eza --tree";
        cat = "bat";
        grep = "rg";

        # tmux: attach to existing session or start new one
        ta = "tmux attach 2>/dev/null || tmux";

        # NixOS shortcuts
        rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#${osConfig.networking.hostName}";
      };

      history = {
        size = 10000;
        save = 10000;
        ignoreDups = true;
        share = true; # share history across terminals
      };

      initContent = ''
        eval "$(keychain --quiet --eval ~/.ssh/id_ed25519)"

        # Vi mode
        bindkey -v   # emacs keybindings (change to -v for vi)

        # Better history search
        bindkey '^R' history-incremental-search-backward

        # fzf keybindings
        source ${pkgs.fzf}/share/fzf/key-bindings.zsh
        source ${pkgs.fzf}/share/fzf/completion.zsh
      '';
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true; # Compiles hooks straight into Zsh
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[❯](green)";
          error_symbol = "[❯](red)";
        };
        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
        };

        git_branch = {
          symbol = " ";
        };

        package.disabled = true;
      };
    };
  };
}
