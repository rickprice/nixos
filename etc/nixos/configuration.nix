# vim: set ts=2 sw=2 et:
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "daw"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "dvorak";
  };

  # Configure console keymap
  console.keyMap = "dvorak";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Realtime extensions
  security.rtkit.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  services.pipewire.extraConfig.pipewire."92-low-latency" = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.quantum" = 128;
      "default.clock.min-quantum" = 64;
    };
  };

  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "99"; }
    { domain = "@audio"; item = "nofile";  type = "soft"; value = "99999"; }
    { domain = "@audio"; item = "nofile";  type = "hard"; value = "99999"; }
  ];

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable ZSH
  programs.zsh = {
  enable = true;
  enableCompletion = true;
  autosuggestions.enable = true;
  syntaxHighlighting.enable = true;
  shellAliases = {
      ll = "ls -lah";
      update-nixos = "sudo nixos-rebuild switch --flake /etc/nixos#daw";
  };
  histSize = 100000;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."fprice" = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4eQjR+UTyw5EC13J/7o8M5XGhiQaha6wx/HyfFzW2l rprice@pricemail.ca"
    ];
    description = "Frederick Price";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "audio" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  neovim
  git
  gh
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;  # recommended: keys only
      PermitRootLogin = "no";
    };
  };

  # Tailscale
  services.tailscale = {
  enable = true;
  useRoutingFeatures = "client";
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

# Disable automatic hibernation
  systemd.sleep.settings = {
    Sleep = {
      # Allows you to still run manual hibernation commands
      AllowHibernation = "yes"; 
      AllowHybridSleep = "no";
      AllowSuspendThenHibernate = "no";
    };
};


  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── midi-daemon ─────────────────────────────────────────────────────────────
  environment.etc."midi-daemon".source = ./files/midi-daemon;

  services.midi-daemon = {
    enable = true;
    configFile = "/etc/midi-daemon/config.toml";
    routesDir  = "/etc/midi-daemon/routes.d";
  };



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
