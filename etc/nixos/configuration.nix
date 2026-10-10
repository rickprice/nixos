# vim: set ts=2 sw=2 et:
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  # Forces a from-source rebuild (losing the binary cache for these) so the
  # DSP code gets -march=native/-mtune=native. Safe here since every host
  # builds its own config locally rather than fetching a shared substitute.
  #
  # Packages on newer nixpkgs (e.g. lsp-plugins) set these via the structured
  # `env` attrset instead of as plain derivation attributes; mkDerivation
  # errors if the same var ends up defined both ways, so match whichever
  # mechanism each package already uses.
  nativeOpt = pkg: pkg.overrideAttrs (old:
    if old ? env then {
      env = old.env // {
        NIX_CFLAGS_COMPILE   = "${old.env.NIX_CFLAGS_COMPILE or ""} -march=native -mtune=native";
        NIX_CXXFLAGS_COMPILE = "${old.env.NIX_CXXFLAGS_COMPILE or ""} -march=native -mtune=native";
      };
    } else {
      NIX_CFLAGS_COMPILE   = "${old.NIX_CFLAGS_COMPILE or ""} -march=native -mtune=native";
      NIX_CXXFLAGS_COMPILE = "${old.NIX_CXXFLAGS_COMPILE or ""} -march=native -mtune=native";
    }
  );

  audioPlugins = [
    (nativeOpt pkgs.calf)
    (nativeOpt pkgs.caps)
    (nativeOpt pkgs.guitarix)
    (nativeOpt pkgs.ladspaPlugins)   # Steve Harris SWH plugins (fast_lookahead_limiter, etc.)
    (nativeOpt pkgs.lsp-plugins)
    (nativeOpt pkgs.sfizz-ui)
    (nativeOpt pkgs.x42-plugins)
    (nativeOpt pkgs.dragonfly-reverb)
    pkgs.volumepanningstereo-lv2 # already built per-host with -march=native in its own Makefile
    (nativeOpt pkgs.zam-plugins)     # ZamCompX2-ladspa
  ];

  # This config is shared across every host (daw, fwork, tprice, eric), but
  # each host's graphical session belongs to a different primary user.
  autorandrPrimaryUser =
    if config.networking.hostName == "tprice" then "tprice"
    else if config.networking.hostName == "eric" then "eric"
    else "fprice";
in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # mkDefault: on daw/fwork, musnix.kernel.realtime (config/modules/musnix-audio.nix)
  # overrides this with a PREEMPT_RT build of the same kernel branch.
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # threadirqs: force all IRQ handlers into schedulable threads so the RT
  # audio thread can preempt them.  nosoftlockup silences the watchdog that
  # would otherwise fire on long-running RT bursts.
  boot.kernelParams = [ "threadirqs" "nosoftlockup" ];

  # Bridge raw USB MIDI devices into the ALSA sequencer so rtmidi-based apps
  # (midisnoop, etc.) can subscribe and receive events, not just enumerate port names.
  boot.kernelModules = [ "snd-seq-midi" ];

  # Remove the 95 % CPU-time cap on SCHED_FIFO/SCHED_RR tasks.  On a
  # dedicated DAW there is no reason to throttle RT threads.
  boot.kernel.sysctl = {
    "kernel.sched_rt_runtime_us"    = -1;
    # Keep swap out of the hot path; 10 means "swap only under real pressure".
    # mkDefault: musnix (daw/fwork) sets this plainly to the same value and
    # should be the authority there; this is just the value for tprice/eric,
    # which don't import musnix.
    "vm.swappiness"                 = lib.mkDefault 10;
    # Reduce how aggressively the kernel flushes dirty pages — large flushes
    # cause latency spikes while the disk is busy.
    "vm.dirty_background_ratio"     = 20;
    "vm.dirty_ratio"                = 40;
    # Allow unprivileged perf usage for latency profiling tools.
    "kernel.perf_event_paranoid"    = 1;
  };

  networking.hostName = "daw"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Use systemd-resolved for DNS. When resolved is running, tailscaled uses its
  # D-Bus API to register MagicDNS per-interface rather than overwriting
  # /etc/resolv.conf entirely. This keeps the local router DNS as a fallback so
  # DNS doesn't break when Tailscale's MagicDNS has issues.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      FallbackDNS = "1.1.1.1 9.9.9.9";
    };
  };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Time synchronization via chrony (replaces systemd-timesyncd).
  services.chrony.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.settings.General.Numlock = "on";
  services.desktopManager.plasma6.enable = true;

  # XMonad window manager (available alongside KDE in the SDDM session chooser)
  services.xserver.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
    extraPackages = hpkgs: [ hpkgs.hostname ];
  };

  # Configure keymap in X11 with two groups: dvorak (default) and QWERTY
  services.xserver.xkb = {
    layout = "us,us";
    variant = "dvorak,";
  };

  # Configure console keymap
  console.keyMap = "dvorak";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Network scanning via SANE + airscan (eSCL / AirScan / WSD)
  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.sane-airscan ];

  # Avahi (mDNS) — required for scanner auto-discovery on the local network
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      userServices = true; # allows apps like TouchOSC to advertise services
    };
  };

  # GPU — AMD Navi 10 (gfx1010). clr provides the libraries; clr.icd installs
  # the vendor ICD file into /run/opengl-driver/etc/OpenCL/vendors/ so the
  # ICD loader can discover the driver.
  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr
    rocmPackages.clr.icd
  ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  # UMC404HD-specific filter-chain/EQ/combine-stream config moved to
  # config/modules/umc404hd-pipewire.nix (daw/fwork only, imported in
  # flake.nix); this is just the baseline every host needs.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
  };

  # mkForce: nixpkgs' own nixos/modules/config/shells-environment.nix sets
  # plain-priority defaults for these same names (generic profile-dir search
  # paths), which conflicted with the assignment below once musnix's own
  # environment.sessionVariables entries forced strict evaluation of the
  # merged environment (this conflict predates musnix and is unrelated to
  # it — musnix sets these under sessionVariables, a different option, with
  # mkDefault). Our native-optimized plugin set should always win here.
  environment.variables = {
    LV2_PATH    = lib.mkForce (lib.makeSearchPath "lib/lv2"    audioPlugins);
    LADSPA_PATH = lib.mkForce (lib.makeSearchPath "lib/ladspa" audioPlugins);
    VST3_PATH   = lib.mkForce (lib.makeSearchPath "lib/vst3"   audioPlugins);
  };

  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "99"; }
    { domain = "@audio"; item = "nofile";  type = "soft"; value = "99999"; }
    { domain = "@audio"; item = "nofile";  type = "hard"; value = "99999"; }
  ];

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  services.libinput.touchpad.disableWhileTyping = true;

  # Enable ZSH
  programs.zsh = {
  enable = true;
  enableCompletion = true;
  autosuggestions.enable = true;
  syntaxHighlighting.enable = true;
  shellAliases = {
      ll = "ls -lah";
      update-nixos = "sudo nixos-rebuild switch --flake /etc/nixos#${config.networking.hostName}";
  };
  histSize = 100000;
  };

  # Define a user account. Don’t forget to set a password with ‘passwd’.
  users.users."tprice" = {
    isNormalUser = true;
    description = "Tamara Price";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "audio" "scanner" "lp" ];
  };

  users.users."eric" = {
    isNormalUser = true;
    description = "Eric MacDonald";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "audio" ];
    hashedPassword = "$y$j9T$05tWRp6MgavEVRBqtKdb9/$6XnVZyqOWOA7OiQHYLzEDtq1yHRamP0mMxWaO5o/mx1";
  };

  users.users."fprice" = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4eQjR+UTyw5EC13J/7o8M5XGhiQaha6wx/HyfFzW2l rprice@pricemail.ca"
    ];
    description = "Frederick Price";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "audio" "scanner" "lp" ];
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
  keychain
  picom
  psmisc
  simple-scan
  flameshot
  alsa-utils
  numlockx
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
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    # Allow password auth from Tailscale (100.64.0.0/10) only.
    # Tailscale account access is the first factor; SSH password is the second.
    # KbdInteractiveAuthentication is intentionally excluded: JuiceSSH (Trilead
    # SSH2) hangs on PAM challenge-response and times out. Plain password auth
    # sends the credential directly to PAM without a conversation loop.
    extraConfig = ''
      Match Address 100.64.0.0/10
        PasswordAuthentication yes
    '';
  };

  # pam_unix is required in the sshd auth stack for password auth to work.
  # NixOS defaults to pam_deny when PasswordAuthentication is globally disabled.
  security.pam.services.sshd.unixAuth = lib.mkForce true;

  # ── keyd (keyboard remapping) ───────────────────────────────────────────────
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" "-047d:1020" ];
        settings = {
          main = {
            capslock = "overload(ctrl_vim, esc)";
            "meta.c" = "C-c";
            "meta.v" = "C-v";
            "meta.x" = "C-x";
            "meta.a" = "C-a";
          };
          fkey_remap = {
            f1 = "f13";
            f2 = "f14";
            f3 = "f15";
            f4 = "f16";
            f5 = "f17";
            f6 = "f18";
            f7 = "f19";
            f8 = "f20";
            f9 = "f21";
            f10 = "f22";
            f11 = "f23";
            f12 = "macro(S-f23)";
          };
          "ctrl_vim:C" = {
            space = "toggle(fkey_remap)";
          };
          shift = {
            leftshift = "timeout(leftshift, 1000, capslock)";
            rightshift = "timeout(rightshift, 1000, capslock)";
          };
        };
      };
      "12keymini" = {
        ids = [ "1189:8890" ];
        settings = {
          main = {
            f1 = "f13";
            f2 = "f14";
            f3 = "f15";
            f4 = "f16";
            f5 = "f17";
            f6 = "f18";
            f7 = "f19";
            f8 = "f20";
            f9 = "f21";
            f10 = "f22";
            f11 = "f23";
            f12 = "macro(S-f23)";
          };
        };
      };
      staplesmini = {
        ids = [ "1c4f:0002" ];
        settings = { };
      };
    };
  };

  # Autorandr — triggers autorandr on display hotplug via udev
  services.autorandr.enable = true;
  # --batch mode has a race condition (ProcessLookupError) in 1.15; delegate to
  # the user service instead so autorandr runs in the session of whoever
  # actually logs into this host.
  systemd.services.autorandr.serviceConfig.ExecStart = lib.mkForce
    "${pkgs.systemd}/bin/systemctl --machine=${autorandrPrimaryUser}@.host --user start autorandr.service";

  # Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # The NixOS drop-in adds After=NetworkManager-wait-online.service but not
  # Wants=, so systemd never activates it and tailscaled races ahead of DHCP.
  # Adding Wants=network-online.target pulls NM-wait-online into the dependency
  # chain, ensuring a lease exists before tailscaled starts.
  systemd.services.tailscaled = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
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

# Power button → clean shutdown
  services.logind.settings.Login.HandlePowerKey = "poweroff";

  # Allow any local user to power off regardless of which VT is active.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id === "org.freedesktop.login1.power-off" ||
           action.id === "org.freedesktop.login1.power-off-multiple-sessions") &&
          subject.local) {
        return polkit.Result.YES;
      }
    });
  '';

# Disable automatic hibernation
  systemd.sleep.settings = {
    Sleep = {
      # Allows you to still run manual hibernation commands
      AllowHibernation = "yes"; 
      AllowHybridSleep = "no";
      AllowSuspendThenHibernate = "no";
    };
};


  # PAM service for KDE screen locker (kscreenlocker_greet uses service name "kde")
  security.pam.services.kde.enable = true;

  # Enable libopenraw GDK Pixbuf loader so tumbler/pcmanfm can thumbnail RAW files (.cr2, etc.)
  programs.gdk-pixbuf.modulePackages = [ pkgs.libopenraw ];

  # xscreensaver needs a SUID wrapper and /etc/pam.d/xscreensaver to authenticate.
  # programs.xscreensaver.enable gives us the sonar SUID wrapper and package.
  # We also need xscreensaver-auth as SUID root and its own PAM service.
  programs.xscreensaver.enable = true;
  security.wrappers.xscreensaver-auth = {
    setuid = true;
    owner = "root";
    group = "root";
    source = "${pkgs.xscreensaver}/libexec/xscreensaver/xscreensaver-auth";
  };
  security.pam.services.xscreensaver.enable = true;

  # Unlock KWallet automatically on SDDM login (applies to all users)
  security.pam.services.sddm.kwallet = {
    enable = true;
    package = pkgs.kdePackages.kwallet-pam;
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Limit parallel builds to avoid OOM SIGKILL during compilation.
  nix.settings.max-jobs = 2;
  nix.settings.cores = 2;

  # ── midi-daemon ─────────────────────────────────────────────────────────────
  # Config/routes deployed system-wide; the daemon itself now runs as a
  # systemd --user service (see non-fprice.nix) so it can be ordered after
  # non-mixer-xt, which only exists once fprice's graphical session starts.
  environment.etc."midi-daemon".source = ./files/midi-daemon;



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
