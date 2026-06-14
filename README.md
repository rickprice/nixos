# nixos
My Nixos configuration

## To setup
Install Nixos on the machine using their USB installer

Edit the initial Nixos configuration file to add git to the machine:

```sudo nano /etc/configuration.nix```

Look for the following

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

And make it look like this:

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  neovim
  git
  ];

This adds neovim and git to the machine

Run:

```sudo nixos-rebuild switch```

Git will now be working on the machine

Then run from the home directory:

```git clone https://github.com/rickprice/nixos.git```

Go to the "nixos" directory and run:

```NukeAndInstall.sh```

This will put the Nixos configurations in place, then run:

```sudo nixos-rebuild switch```

The machine should now be configured. Then run:

```gh repo clone rickprice/nixos .nixos```

Go to the ".nixos" directory and run:

```NukeAndInstall.sh```

This will put the Nixos configurations in place, then run:

```sudo nixos-rebuild switch```

Then delete the nixos directory since it will now be a duplicate
