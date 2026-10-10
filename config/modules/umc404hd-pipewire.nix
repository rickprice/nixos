{ pkgs, ... }:
{
  # Make LADSPA plugins available inside the pipewire service (affects the
  # LADSPA_PATH baked into the systemd unit, not just the user session) —
  # needed by the "10-umc404hd-compressed" filter-chain below.
  services.pipewire.extraLadspaPackages = [ pkgs.zam-plugins pkgs.ladspaPlugins ];

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

  # Bypass UCM/ACP so the UMC404HD appears as a flat 4-channel device with
  # AUX0-3 numbered ports. Required so the loopback and filter-chain sinks
  # below can target specific AUX channel pairs. Without this WirePlumber
  # applies ALSA Card Profiles and splits the device into HiFi nodes instead.
  services.pipewire.wireplumber.extraConfig."51-umc404-direct" = {
    "monitor.alsa.rules" = [
      { matches = [ { "device.name" = "alsa_card.usb-BEHRINGER_UMC404HD_192k-00"; } ];
        actions.update-props."api.alsa.use-acp" = false;
      }
      { matches = [ { "node.name" = "~alsa_output.*BEHRINGER_UMC404HD.*"; } ];
        actions.update-props = {
          "node.nick"        = "UMC404HD";
          "node.description" = "UMC404HD";
          "audio.position"   = [ "AUX0" "AUX1" "AUX2" "AUX3" ];
        };
      }
      { matches = [ { "node.name" = "~alsa_input.*BEHRINGER_UMC404HD.*"; } ];
        actions.update-props = {
          "node.nick"        = "UMC404HD";
          "node.description" = "UMC404HD";
          "audio.position"   = [ "AUX0" "AUX1" "AUX2" "AUX3" ];
        };
      }
    ];
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
      # Best-estimate speaker correction EQ for the Optimus PRO-X44AV on the USB
      # 2.0 amplifier. The PRO-X44AV is a small ported bookshelf speaker with a 4"
      # woofer; its bass rolls off below ~150 Hz. This filter-chain replaces the
      # plain loopback to add compensation without changing the node name (so the
      # combine-stream below still finds usb20_out). node.passive keeps the dongle
      # from blocking the graph when unplugged.
      #
      # EQ rationale (starting-point; replace with REW measurements when available):
      #   HP  60 Hz Q=0.71  cut inaudible sub-bass the woofer can't reproduce
      #   +2 dB  80 Hz Q=1.5  bass punch (reduced from +4 dB; was boomy)
      #   +4 dB 150 Hz Q=1.2  warmth / body (reduced from +5 dB; was boomy)
      #   +4 dB 250 Hz Q=1.0  fullness
      #   -1 dB 500 Hz Q=1.5  reduce muddiness
      #   -1 dB 3 kHz  Q=2.0  tame presence harshness
      #   -1 dB 8 kHz  Q=1.5  soften treble slightly
      { name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "USB 2.0 Audio Dongle";
          "media.name"       = "USB 2.0 Audio Dongle";
          "filter.graph" = {
            nodes = [
              # Left channel
              { type = "builtin"; name = "hp_l";    label = "bq_highpass"; control = { "Freq" = 60;   "Q" = 0.71; }; }
              { type = "builtin"; name = "eq_l_1";  label = "bq_peaking";  control = { "Freq" = 80;   "Q" = 1.5;  "Gain" =  2.0; }; }
              { type = "builtin"; name = "eq_l_2";  label = "bq_peaking";  control = { "Freq" = 150;  "Q" = 1.2;  "Gain" =  4.0; }; }
              { type = "builtin"; name = "eq_l_3";  label = "bq_peaking";  control = { "Freq" = 250;  "Q" = 1.0;  "Gain" =  4.0; }; }
              { type = "builtin"; name = "eq_l_4";  label = "bq_peaking";  control = { "Freq" = 500;  "Q" = 1.5;  "Gain" = -1.0; }; }
              { type = "builtin"; name = "eq_l_5";  label = "bq_peaking";  control = { "Freq" = 3000; "Q" = 2.0;  "Gain" = -1.0; }; }
              { type = "builtin"; name = "eq_l_6";  label = "bq_peaking";  control = { "Freq" = 8000; "Q" = 1.5;  "Gain" = -1.0; }; }
              # Right channel
              { type = "builtin"; name = "hp_r";    label = "bq_highpass"; control = { "Freq" = 60;   "Q" = 0.71; }; }
              { type = "builtin"; name = "eq_r_1";  label = "bq_peaking";  control = { "Freq" = 80;   "Q" = 1.5;  "Gain" =  2.0; }; }
              { type = "builtin"; name = "eq_r_2";  label = "bq_peaking";  control = { "Freq" = 150;  "Q" = 1.2;  "Gain" =  4.0; }; }
              { type = "builtin"; name = "eq_r_3";  label = "bq_peaking";  control = { "Freq" = 250;  "Q" = 1.0;  "Gain" =  4.0; }; }
              { type = "builtin"; name = "eq_r_4";  label = "bq_peaking";  control = { "Freq" = 500;  "Q" = 1.5;  "Gain" = -1.0; }; }
              { type = "builtin"; name = "eq_r_5";  label = "bq_peaking";  control = { "Freq" = 3000; "Q" = 2.0;  "Gain" = -1.0; }; }
              { type = "builtin"; name = "eq_r_6";  label = "bq_peaking";  control = { "Freq" = 8000; "Q" = 1.5;  "Gain" = -1.0; }; }
            ];
            links = [
              { output = "hp_l:Out";   input = "eq_l_1:In"; }
              { output = "eq_l_1:Out"; input = "eq_l_2:In"; }
              { output = "eq_l_2:Out"; input = "eq_l_3:In"; }
              { output = "eq_l_3:Out"; input = "eq_l_4:In"; }
              { output = "eq_l_4:Out"; input = "eq_l_5:In"; }
              { output = "eq_l_5:Out"; input = "eq_l_6:In"; }
              { output = "hp_r:Out";   input = "eq_r_1:In"; }
              { output = "eq_r_1:Out"; input = "eq_r_2:In"; }
              { output = "eq_r_2:Out"; input = "eq_r_3:In"; }
              { output = "eq_r_3:Out"; input = "eq_r_4:In"; }
              { output = "eq_r_4:Out"; input = "eq_r_5:In"; }
              { output = "eq_r_5:Out"; input = "eq_r_6:In"; }
            ];
            inputs  = [ "hp_l:In"    "hp_r:In"    ];
            outputs = [ "eq_l_6:Out" "eq_r_6:Out" ];
          };
          "capture.props" = {
            "node.name"      = "usb20_out";
            "media.class"    = "Audio/Sink";
            "audio.position" = [ "FL" "FR" ];
          };
          "playback.props" = {
            "node.name"         = "usb20_out_play";
            "audio.position"    = [ "FL" "FR" ];
            "target.object"     = "alsa_output.usb-Generic_USB2.0_Device_20170726905959-00.analog-stereo";
            "stream.dont-remix" = true;
            "node.passive"      = true;
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

  # Native PipeWire combine-stream: merges umc404hd_out12 + umc404hd_out34 into a
  # single "UMC404HD All Outputs" sink visible in the PipeWire graph.
  # Using libpipewire-module-combine-stream instead of pactl module-combine-sink so
  # the node appears as a first-class PipeWire node (helvum, qpwgraph, etc.).
  services.pipewire.extraConfig.pipewire."11-umc404hd-combined" = {
    "context.modules" = [
      { name = "libpipewire-module-combine-stream";
        args = {
          "node.name"        = "umc404hd_combined";
          "node.description" = "UMC404HD All Outputs";
          "media.class"      = "Audio/Sink";
          "combine.mode"     = "sink";
          "stream.rules" = [
            { matches = [ { "node.name" = "umc404hd_out12"; } ];
              actions.create-stream = { "audio.position" = [ "FL" "FR" ]; };
            }
            { matches = [ { "node.name" = "umc404hd_out34"; } ];
              actions.create-stream = { "audio.position" = [ "FL" "FR" ]; };
            }
            # Routes to usb20_out (a loopback virtual sink) which forwards to the
            # physical ALSA dongle. combine-stream cannot target ALSA nodes directly.
            { matches = [ { "node.name" = "usb20_out"; } ];
              actions.create-stream = { "audio.position" = [ "FL" "FR" ]; };
            }
          ];
        };
      }
    ];
  };

  # PipeWire-Pulse drop-in: tighten speech-dispatcher latency floor.
  services.pipewire.extraConfig.pipewire-pulse."10-umc404hd" = {
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
}
