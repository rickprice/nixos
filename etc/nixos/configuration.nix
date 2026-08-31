# vim: set ts=2 sw=2 et:
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  audioPlugins = [
    pkgs.calf
    pkgs.caps
    pkgs.guitarix
    pkgs.ladspaPlugins   # Steve Harris SWH plugins (fast_lookahead_limiter, etc.)
    pkgs.lsp-plugins
    pkgs.sfizz-ui
    pkgs.x42-plugins
    pkgs.dragonfly-reverb
    pkgs.volumepanningstereo-lv2
    pkgs.zam-plugins     # ZamCompX2-ladspa
  ];
in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Mainline kernel — for hard real-time scheduling switch to pkgs.linuxPackages_rt_latest.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # threadirqs: force all IRQ handlers into schedulable threads so the RT
  # audio thread can preempt them.  nosoftlockup silences the watchdog that
  # would otherwise fire on long-running RT bursts.
  boot.kernelParams = [ "threadirqs" "nosoftlockup" ];

  # Remove the 95 % CPU-time cap on SCHED_FIFO/SCHED_RR tasks.  On a
  # dedicated DAW there is no reason to throttle RT threads.
  boot.kernel.sysctl = {
    "kernel.sched_rt_runtime_us"    = -1;
    # Keep swap out of the hot path; 10 means "swap only under real pressure".
    "vm.swappiness"                 = 10;
    # Reduce how aggressively the kernel flushes dirty pages — large flushes
    # cause latency spikes while the disk is busy.
    "vm.dirty_background_ratio"     = 20;
    "vm.dirty_ratio"                = 40;
    # Allow unprivileged perf usage for latency profiling tools.
    "kernel.perf_event_paranoid"    = 1;
  };

  # Keep the CPU at full frequency so there are no scaling-induced latency
  # spikes during a session.  The i3-1005G1 is fanless-class so thermals are
  # fine under the light computational load of a DAW.
  powerManagement.cpuFreqGovernor = "performance";

  networking.hostName = "daw"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

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

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

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
      "default.clock.rate"        = 48000;
      "default.clock.quantum"     = 128;
      "default.clock.min-quantum" = 64;
      "default.clock.max-quantum" = 128;
      # Allow PipeWire itself to lock pages in RAM so the audio graph never
      # takes a page-fault during processing.
      "mem.allow-mlock"           = true;
    };
  };

  # Expose the same quantum/rate constraints to JACK clients (Ardour, Carla,
  # etc.) so they see a consistent period size and cannot negotiate a larger one.
  services.pipewire.extraConfig.jack."92-low-latency" = {
    "context.properties" = {
      "default.clock.rate"        = 48000;
      "default.clock.quantum"     = 128;
      "default.clock.min-quantum" = 64;
      "default.clock.max-quantum" = 128;
    };
  };

  # Loopback sink for UMC404HD outputs 1+2 (flat, AUX0/AUX1) and a 30-band EQ
  # filter-chain sink for outputs 3+4 (AUX2/AUX3). Both are required by the
  # umc404hd_combined combine-sink loaded in the pipewire-pulse drop-in.
  services.pipewire.extraConfig.pipewire."09-umc404hd-split" = {
    "context.modules" = [
      { name = "libpipewire-module-loopback";
        args = {
          "node.description" = "UMC404HD Outputs 1+2";
          "capture.props" = {
            "node.name"      = "umc404hd_out12";
            "media.class"    = "Audio/Sink";
            "audio.position" = [ "FL" "FR" ];
          };
          "playback.props" = {
            "node.name"         = "umc404hd_out12_play";
            "audio.position"    = [ "AUX0" "AUX1" ];
            "target.object"     = "alsa_output.usb-BEHRINGER_UMC404HD_192k-00.playback.0.0";
            "stream.dont-remix" = true;
          };
        };
      }
      { name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "UMC404HD Outputs 3+4";
          "media.name"       = "UMC404HD Outputs 3+4";
          "filter.graph" = {
            nodes = [
              # Left channel EQ
              { type = "builtin"; name = "eq_l_1";  label = "bq_peaking"; control = { "Freq" = 20;    "Q" = 4.36; "Gain" =  2.4; }; }
              { type = "builtin"; name = "eq_l_2";  label = "bq_peaking"; control = { "Freq" = 25;    "Q" = 4.36; "Gain" =  0.8; }; }
              { type = "builtin"; name = "eq_l_3";  label = "bq_peaking"; control = { "Freq" = 32;    "Q" = 4.36; "Gain" = -0.1; }; }
              { type = "builtin"; name = "eq_l_4";  label = "bq_peaking"; control = { "Freq" = 40;    "Q" = 4.36; "Gain" = -0.9; }; }
              { type = "builtin"; name = "eq_l_5";  label = "bq_peaking"; control = { "Freq" = 50;    "Q" = 4.36; "Gain" =  0.3; }; }
              { type = "builtin"; name = "eq_l_6";  label = "bq_peaking"; control = { "Freq" = 63;    "Q" = 4.36; "Gain" = -1.5; }; }
              { type = "builtin"; name = "eq_l_7";  label = "bq_peaking"; control = { "Freq" = 80;    "Q" = 4.36; "Gain" = -1.9; }; }
              { type = "builtin"; name = "eq_l_8";  label = "bq_peaking"; control = { "Freq" = 101;   "Q" = 4.36; "Gain" = -4.5; }; }
              { type = "builtin"; name = "eq_l_9";  label = "bq_peaking"; control = { "Freq" = 127;   "Q" = 4.36; "Gain" = -5.0; }; }
              { type = "builtin"; name = "eq_l_10"; label = "bq_peaking"; control = { "Freq" = 160;   "Q" = 4.36; "Gain" = -5.0; }; }
              { type = "builtin"; name = "eq_l_11"; label = "bq_peaking"; control = { "Freq" = 202;   "Q" = 4.36; "Gain" = -3.7; }; }
              { type = "builtin"; name = "eq_l_12"; label = "bq_peaking"; control = { "Freq" = 254;   "Q" = 4.36; "Gain" = -2.8; }; }
              { type = "builtin"; name = "eq_l_13"; label = "bq_peaking"; control = { "Freq" = 320;   "Q" = 4.36; "Gain" =  0.2; }; }
              { type = "builtin"; name = "eq_l_14"; label = "bq_peaking"; control = { "Freq" = 403;   "Q" = 4.36; "Gain" =  1.8; }; }
              { type = "builtin"; name = "eq_l_15"; label = "bq_peaking"; control = { "Freq" = 508;   "Q" = 4.36; "Gain" =  2.7; }; }
              { type = "builtin"; name = "eq_l_16"; label = "bq_peaking"; control = { "Freq" = 640;   "Q" = 4.36; "Gain" =  4.3; }; }
              { type = "builtin"; name = "eq_l_17"; label = "bq_peaking"; control = { "Freq" = 806;   "Q" = 4.36; "Gain" =  2.7; }; }
              { type = "builtin"; name = "eq_l_18"; label = "bq_peaking"; control = { "Freq" = 1016;  "Q" = 4.36; "Gain" =  2.7; }; }
              { type = "builtin"; name = "eq_l_19"; label = "bq_peaking"; control = { "Freq" = 1280;  "Q" = 4.36; "Gain" =  1.8; }; }
              { type = "builtin"; name = "eq_l_20"; label = "bq_peaking"; control = { "Freq" = 1613;  "Q" = 4.36; "Gain" =  2.4; }; }
              { type = "builtin"; name = "eq_l_21"; label = "bq_peaking"; control = { "Freq" = 2032;  "Q" = 4.36; "Gain" =  1.3; }; }
              { type = "builtin"; name = "eq_l_22"; label = "bq_peaking"; control = { "Freq" = 2560;  "Q" = 4.36; "Gain" = -0.7; }; }
              { type = "builtin"; name = "eq_l_23"; label = "bq_peaking"; control = { "Freq" = 3225;  "Q" = 4.36; "Gain" = -0.8; }; }
              { type = "builtin"; name = "eq_l_24"; label = "bq_peaking"; control = { "Freq" = 4064;  "Q" = 4.36; "Gain" =  4.1; }; }
              { type = "builtin"; name = "eq_l_25"; label = "bq_peaking"; control = { "Freq" = 5120;  "Q" = 4.36; "Gain" = -0.9; }; }
              { type = "builtin"; name = "eq_l_26"; label = "bq_peaking"; control = { "Freq" = 6451;  "Q" = 4.36; "Gain" = -1.9; }; }
              { type = "builtin"; name = "eq_l_27"; label = "bq_peaking"; control = { "Freq" = 8127;  "Q" = 4.36; "Gain" = -2.4; }; }
              { type = "builtin"; name = "eq_l_28"; label = "bq_peaking"; control = { "Freq" = 10240; "Q" = 4.36; "Gain" = -2.2; }; }
              { type = "builtin"; name = "eq_l_29"; label = "bq_peaking"; control = { "Freq" = 12902; "Q" = 4.36; "Gain" = -3.7; }; }
              { type = "builtin"; name = "eq_l_30"; label = "bq_peaking"; control = { "Freq" = 16255; "Q" = 4.36; "Gain" = -3.8; }; }
              # Right channel EQ (identical curve)
              { type = "builtin"; name = "eq_r_1";  label = "bq_peaking"; control = { "Freq" = 20;    "Q" = 4.36; "Gain" =  2.4; }; }
              { type = "builtin"; name = "eq_r_2";  label = "bq_peaking"; control = { "Freq" = 25;    "Q" = 4.36; "Gain" =  0.8; }; }
              { type = "builtin"; name = "eq_r_3";  label = "bq_peaking"; control = { "Freq" = 32;    "Q" = 4.36; "Gain" = -0.1; }; }
              { type = "builtin"; name = "eq_r_4";  label = "bq_peaking"; control = { "Freq" = 40;    "Q" = 4.36; "Gain" = -0.9; }; }
              { type = "builtin"; name = "eq_r_5";  label = "bq_peaking"; control = { "Freq" = 50;    "Q" = 4.36; "Gain" =  0.3; }; }
              { type = "builtin"; name = "eq_r_6";  label = "bq_peaking"; control = { "Freq" = 63;    "Q" = 4.36; "Gain" = -1.5; }; }
              { type = "builtin"; name = "eq_r_7";  label = "bq_peaking"; control = { "Freq" = 80;    "Q" = 4.36; "Gain" = -1.9; }; }
              { type = "builtin"; name = "eq_r_8";  label = "bq_peaking"; control = { "Freq" = 101;   "Q" = 4.36; "Gain" = -4.5; }; }
              { type = "builtin"; name = "eq_r_9";  label = "bq_peaking"; control = { "Freq" = 127;   "Q" = 4.36; "Gain" = -5.0; }; }
              { type = "builtin"; name = "eq_r_10"; label = "bq_peaking"; control = { "Freq" = 160;   "Q" = 4.36; "Gain" = -5.0; }; }
              { type = "builtin"; name = "eq_r_11"; label = "bq_peaking"; control = { "Freq" = 202;   "Q" = 4.36; "Gain" = -3.7; }; }
              { type = "builtin"; name = "eq_r_12"; label = "bq_peaking"; control = { "Freq" = 254;   "Q" = 4.36; "Gain" = -2.8; }; }
              { type = "builtin"; name = "eq_r_13"; label = "bq_peaking"; control = { "Freq" = 320;   "Q" = 4.36; "Gain" =  0.2; }; }
              { type = "builtin"; name = "eq_r_14"; label = "bq_peaking"; control = { "Freq" = 403;   "Q" = 4.36; "Gain" =  1.8; }; }
              { type = "builtin"; name = "eq_r_15"; label = "bq_peaking"; control = { "Freq" = 508;   "Q" = 4.36; "Gain" =  2.7; }; }
              { type = "builtin"; name = "eq_r_16"; label = "bq_peaking"; control = { "Freq" = 640;   "Q" = 4.36; "Gain" =  4.3; }; }
              { type = "builtin"; name = "eq_r_17"; label = "bq_peaking"; control = { "Freq" = 806;   "Q" = 4.36; "Gain" =  2.7; }; }
              { type = "builtin"; name = "eq_r_18"; label = "bq_peaking"; control = { "Freq" = 1016;  "Q" = 4.36; "Gain" =  2.7; }; }
              { type = "builtin"; name = "eq_r_19"; label = "bq_peaking"; control = { "Freq" = 1280;  "Q" = 4.36; "Gain" =  1.8; }; }
              { type = "builtin"; name = "eq_r_20"; label = "bq_peaking"; control = { "Freq" = 1613;  "Q" = 4.36; "Gain" =  2.4; }; }
              { type = "builtin"; name = "eq_r_21"; label = "bq_peaking"; control = { "Freq" = 2032;  "Q" = 4.36; "Gain" =  1.3; }; }
              { type = "builtin"; name = "eq_r_22"; label = "bq_peaking"; control = { "Freq" = 2560;  "Q" = 4.36; "Gain" = -0.7; }; }
              { type = "builtin"; name = "eq_r_23"; label = "bq_peaking"; control = { "Freq" = 3225;  "Q" = 4.36; "Gain" = -0.8; }; }
              { type = "builtin"; name = "eq_r_24"; label = "bq_peaking"; control = { "Freq" = 4064;  "Q" = 4.36; "Gain" =  4.1; }; }
              { type = "builtin"; name = "eq_r_25"; label = "bq_peaking"; control = { "Freq" = 5120;  "Q" = 4.36; "Gain" = -0.9; }; }
              { type = "builtin"; name = "eq_r_26"; label = "bq_peaking"; control = { "Freq" = 6451;  "Q" = 4.36; "Gain" = -1.9; }; }
              { type = "builtin"; name = "eq_r_27"; label = "bq_peaking"; control = { "Freq" = 8127;  "Q" = 4.36; "Gain" = -2.4; }; }
              { type = "builtin"; name = "eq_r_28"; label = "bq_peaking"; control = { "Freq" = 10240; "Q" = 4.36; "Gain" = -2.2; }; }
              { type = "builtin"; name = "eq_r_29"; label = "bq_peaking"; control = { "Freq" = 12902; "Q" = 4.36; "Gain" = -3.7; }; }
              { type = "builtin"; name = "eq_r_30"; label = "bq_peaking"; control = { "Freq" = 16255; "Q" = 4.36; "Gain" = -3.8; }; }
            ];
            links = [
              # Left chain
              { output = "eq_l_1:Out";  input = "eq_l_2:In";  }
              { output = "eq_l_2:Out";  input = "eq_l_3:In";  }
              { output = "eq_l_3:Out";  input = "eq_l_4:In";  }
              { output = "eq_l_4:Out";  input = "eq_l_5:In";  }
              { output = "eq_l_5:Out";  input = "eq_l_6:In";  }
              { output = "eq_l_6:Out";  input = "eq_l_7:In";  }
              { output = "eq_l_7:Out";  input = "eq_l_8:In";  }
              { output = "eq_l_8:Out";  input = "eq_l_9:In";  }
              { output = "eq_l_9:Out";  input = "eq_l_10:In"; }
              { output = "eq_l_10:Out"; input = "eq_l_11:In"; }
              { output = "eq_l_11:Out"; input = "eq_l_12:In"; }
              { output = "eq_l_12:Out"; input = "eq_l_13:In"; }
              { output = "eq_l_13:Out"; input = "eq_l_14:In"; }
              { output = "eq_l_14:Out"; input = "eq_l_15:In"; }
              { output = "eq_l_15:Out"; input = "eq_l_16:In"; }
              { output = "eq_l_16:Out"; input = "eq_l_17:In"; }
              { output = "eq_l_17:Out"; input = "eq_l_18:In"; }
              { output = "eq_l_18:Out"; input = "eq_l_19:In"; }
              { output = "eq_l_19:Out"; input = "eq_l_20:In"; }
              { output = "eq_l_20:Out"; input = "eq_l_21:In"; }
              { output = "eq_l_21:Out"; input = "eq_l_22:In"; }
              { output = "eq_l_22:Out"; input = "eq_l_23:In"; }
              { output = "eq_l_23:Out"; input = "eq_l_24:In"; }
              { output = "eq_l_24:Out"; input = "eq_l_25:In"; }
              { output = "eq_l_25:Out"; input = "eq_l_26:In"; }
              { output = "eq_l_26:Out"; input = "eq_l_27:In"; }
              { output = "eq_l_27:Out"; input = "eq_l_28:In"; }
              { output = "eq_l_28:Out"; input = "eq_l_29:In"; }
              { output = "eq_l_29:Out"; input = "eq_l_30:In"; }
              # Right chain
              { output = "eq_r_1:Out";  input = "eq_r_2:In";  }
              { output = "eq_r_2:Out";  input = "eq_r_3:In";  }
              { output = "eq_r_3:Out";  input = "eq_r_4:In";  }
              { output = "eq_r_4:Out";  input = "eq_r_5:In";  }
              { output = "eq_r_5:Out";  input = "eq_r_6:In";  }
              { output = "eq_r_6:Out";  input = "eq_r_7:In";  }
              { output = "eq_r_7:Out";  input = "eq_r_8:In";  }
              { output = "eq_r_8:Out";  input = "eq_r_9:In";  }
              { output = "eq_r_9:Out";  input = "eq_r_10:In"; }
              { output = "eq_r_10:Out"; input = "eq_r_11:In"; }
              { output = "eq_r_11:Out"; input = "eq_r_12:In"; }
              { output = "eq_r_12:Out"; input = "eq_r_13:In"; }
              { output = "eq_r_13:Out"; input = "eq_r_14:In"; }
              { output = "eq_r_14:Out"; input = "eq_r_15:In"; }
              { output = "eq_r_15:Out"; input = "eq_r_16:In"; }
              { output = "eq_r_16:Out"; input = "eq_r_17:In"; }
              { output = "eq_r_17:Out"; input = "eq_r_18:In"; }
              { output = "eq_r_18:Out"; input = "eq_r_19:In"; }
              { output = "eq_r_19:Out"; input = "eq_r_20:In"; }
              { output = "eq_r_20:Out"; input = "eq_r_21:In"; }
              { output = "eq_r_21:Out"; input = "eq_r_22:In"; }
              { output = "eq_r_22:Out"; input = "eq_r_23:In"; }
              { output = "eq_r_23:Out"; input = "eq_r_24:In"; }
              { output = "eq_r_24:Out"; input = "eq_r_25:In"; }
              { output = "eq_r_25:Out"; input = "eq_r_26:In"; }
              { output = "eq_r_26:Out"; input = "eq_r_27:In"; }
              { output = "eq_r_27:Out"; input = "eq_r_28:In"; }
              { output = "eq_r_28:Out"; input = "eq_r_29:In"; }
              { output = "eq_r_29:Out"; input = "eq_r_30:In"; }
            ];
            inputs  = [ "eq_l_1:In"   "eq_r_1:In"   ];
            outputs = [ "eq_l_30:Out" "eq_r_30:Out" ];
          };
          "capture.props" = {
            "node.name"      = "umc404hd_out34";
            "media.class"    = "Audio/Sink";
            "audio.channels" = 2;
            "audio.position" = [ "FL" "FR" ];
          };
          "playback.props" = {
            "node.name"         = "umc404hd_out34_play";
            "audio.channels"    = 2;
            "audio.position"    = [ "AUX2" "AUX3" ];
            "target.object"     = "alsa_output.usb-BEHRINGER_UMC404HD_192k-00.playback.0.0";
            "stream.dont-remix" = true;
          };
        };
      }
    ];
  };

  # Compressor + limiter virtual sink for the UMC404HD microphone input.
  # Creates an Audio/Sink named "umc404hd_compressed" that apps can target;
  # output is routed through umc404hd_combined.
  services.pipewire.extraConfig.pipewire."10-umc404hd-compressed" = {
    "context.modules" = [
      { name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "UMC404HD Compressed";
          "media.name"       = "UMC404HD Compressed";
          "filter.graph" = {
            nodes = [
              { type    = "ladspa";
                name    = "comp";
                plugin  = "ZamCompX2-ladspa";
                label   = "ZamCompX2";
                control = {
                  "Attack"           = 5;
                  "Release"          = 150;
                  "Knee"             = 6;
                  "Ratio"            = 16;
                  "Threshold"        = -28;
                  "Makeup"           = 8;
                  "Slew"             = 1;
                  "Stereo Detection" = 1;
                  "Sidechain"        = 0;
                };
              }
              { type    = "ladspa";
                name    = "limit";
                plugin  = "fast_lookahead_limiter_1913";
                label   = "fastLookaheadLimiter";
                control = {
                  "Input gain (dB)"  = 0;
                  "Limit (dB)"       = -1;
                  "Release time (s)" = 0.3;
                };
              }
            ];
            links = [
              { output = "comp:Audio Output 1";  input = "limit:Input 1"; }
              { output = "comp:Audio Output 2";  input = "limit:Input 2"; }
            ];
            inputs  = [ "comp:Audio Input 1"  "comp:Audio Input 2" ];
            outputs = [ "limit:Output 1"  "limit:Output 2" ];
          };
          "capture.props" = {
            "node.name"      = "umc404hd_compressed";
            "media.class"    = "Audio/Sink";
            "audio.channels" = 2;
            "audio.position" = [ "FL" "FR" ];
          };
          "playback.props" = {
            "node.name"      = "umc404hd_compressed_play";
            "audio.channels" = 2;
            "audio.position" = [ "FL" "FR" ];
            "target.object"  = "umc404hd_combined";
          };
        };
      }
    ];
  };

  # PipeWire-Pulse drop-in: create the umc404hd_combined combine-sink
  # (merges umc404hd_out12 + umc404hd_out34). Also tighten the
  # speech-dispatcher latency floor (dotfiles uses 1024 frames vs NixOS default 512).
  services.pipewire.extraConfig.pipewire-pulse."10-umc404hd" = {
    "context.exec" = [
      { path = "pactl"; args = "load-module module-combine-sink sink_name=umc404hd_combined sink_properties='device.description=\"UMC404HD All Outputs\"' slaves=umc404hd_out12,umc404hd_out34"; }
    ];
    "pulse.rules" = [
      { matches = [ { "application.name" = "~speech-dispatcher.*"; } ];
        actions.update-props = {
          "pulse.min.req"     = "1024/48000";
          "pulse.min.quantum" = "1024/48000";
        };
      }
    ];
  };

  # Tell JACK clients (Carla, Ardour, etc.) to request 128 frames at 48 kHz.
  # Without this Carla falls back to its own default of 512.
  environment.sessionVariables.PIPEWIRE_LATENCY = "128/48000";

  environment.variables = {
    LV2_PATH    = lib.makeSearchPath "lib/lv2"    audioPlugins;
    LADSPA_PATH = lib.makeSearchPath "lib/ladspa" audioPlugins;
    VST3_PATH   = lib.makeSearchPath "lib/vst3"   audioPlugins;
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
      update-nixos = "sudo nixos-rebuild switch --flake /etc/nixos#fwork";
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
  simple-scan
  flameshot
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
