{ pkgs, ... }:

{
  programs.autorandr = {
    enable = true;

    hooks.postswitch = {
      "05_restart_trayer" = ''
        #! /usr/bin/bash
        systemctl --user restart trayer.service
      '';

      "07_numlock" = ''
        #! /usr/bin/bash
        numlockx on
      '';

      # Decoupled from autorandr.service itself: setting the wallpaper needs
      # the Dropbox mount, but trayer/numlock/keyboard above don't, and
      # shouldn't fail just because Dropbox is unreachable. This hook only
      # kicks off autorandr-wallpaper.service and doesn't wait on it or
      # propagate its failure.
      "10_setup_feh" = ''
        #! /usr/bin/bash
        systemctl --user --no-block start autorandr-wallpaper.service
      '';

      # Half of the AND-gate for display-ready.target (see its definition
      # below): marks "autorandr has actually applied a profile this session"
      # and, only once XMonad's startup half has also happened, starts the
      # target. See xmonad-ready.service's comment for why it's an AND rather
      # than either trigger alone. --no-block on the target start because this
      # hook runs synchronously inside autorandr's own still-running process
      # (autorandr.service hasn't exited yet) -- a blocking call here would
      # wait on a job that can't finish until this hook returns. Plain
      # `start`, not `restart`: once these apps are up, a later monitor change
      # doesn't bother them -- only the login-time race does -- so there's no
      # need to bounce them on every subsequent profile switch.
      "15_start_display_ready" = ''
        #! /usr/bin/bash
        systemctl --user start autorandr-settled.service
        systemctl --user is-active --quiet xmonad-ready.service && systemctl --user --no-block start display-ready.target
        true
      '';
    };

    profiles = {
      docked = {
        fingerprint = {
          "DisplayPort-0" =
            "00ffffffffffff001e6d0c5cb326070003200103803c1978ea24e5ae5048a4240e5054256b007140818081c0a9c0b300d1c08100d1cfcd4600a0a0381f4030203a0059fe2000001a023a801871382d40582c450059fe2000001e000000fd00384b1e5a18010a202020202020000000fc004c4720554c545241574944450a0128020331f2230907074b100403011f1359125d5e5f830100006d030c001000b83c200060010203e305c000e60605014a4a56295900a0a038274030203a0059fe2000001a565e00a0a0a029503020350059fe2000001a000000ff003230334e54435a44533635390a000000000000000000000000000000000000000000000000bf";
          "DisplayPort-1" =
            "00ffffffffffff0006b3d227827c0000311e0103803c22782ae925a4554f9a260e5054bfef00d1c0b30095008180814081c0714f0101023a801871382d40582c450056502100001e000000ff004c434c4d54463033313837340a000000fd00304b185412000a202020202020000000fc004153555520564132374548450a01e002032b714f0102031112130414050e0f1d1e1f90230917078301000065030c001000681a00000101304be66842806a703827400820980456502100001a011d007251d01e206e28550056502100001e011d00bc52d01e20b828554056502100001e8c0ad090204031200c405500565021000018000000000000000000000000b7";
          "DisplayPort-2" =
            "00ffffffffffff0010ac15d04c30473206110103802f1e78ee8f30a355499827145054a54b00714f81800101010101010101010101017c2e90a0601a1e4030203600d9281100001a000000ff004b553331313732373247304c0a000000fd00384b1e530e000a202020202020000000fc0044454c4c20453232385746500a00d9";
          "HDMI-A-0" =
            "00ffffffffffff004c2db571000e0001011f0103805f36780aa833ab5045a5270d4848bdef80714f81c0810081809500a9c0b300d1c008e80030f2705a80b0588a00501d7400001e565e00a0a0a0295030203500501d7400001a000000fd00184b0f873c000a202020202020000000fc0053414d53554e470a202020202001ed02035cf05661101f041305142021225d5e5f6065666264071603122f0f5707150750570700675400090707832f0000e2004fe305c3016e030c001000b83c2800800102030468d85dc40178800b02e3060d01e30f01e0e5018b849001023a801871382d40582c450000000000001e000000000000000000000000000000000077";
        };
        config = {
          "HDMI-A-0" = {
            crtc = 2;
            mode = "3840x2160";
            position = "4240x0";
            rate = "60.00";
          };
          "DisplayPort-1" = {
            crtc = 0;
            mode = "1920x1080";
            position = "2320x15";
            primary = true;
            rate = "60.00";
          };
          "DisplayPort-2" = {
            crtc = 3;
            mode = "1680x1050";
            position = "0x1095";
            rate = "59.88";
          };
          "DisplayPort-0" = {
            crtc = 1;
            mode = "2560x1080";
            position = "1680x1095";
            rate = "59.98";
          };
        };
      };

      mobile = {
        fingerprint = {
          "eDP-1" =
            "00ffffffffffff0009e5db0700000000011c0104a51f1178027d50a657529f27125054000000010101010101010101010101010101013a3880de703828403020360035ae1000001afb2c80de703828403020360035ae1000001a000000fe00424f452043510a202020202020000000fe004e4531343046484d2d4e36310a0043";
        };
        config = {
          "DP-1" = {
            enable = false;
          };
          "HDMI-1" = {
            enable = false;
          };
          "DP-2" = {
            enable = false;
          };
          "DP-2-1" = {
            enable = false;
          };
          "DP-2-2" = {
            enable = false;
          };
          "DP-2-3" = {
            enable = false;
          };
          "DP-1-1" = {
            enable = false;
          };
          "DP-1-2" = {
            enable = false;
          };
          "DP-1-3" = {
            enable = false;
          };
          "eDP-1" = {
            crtc = 0;
            mode = "1920x1080";
            position = "0x0";
            primary = true;
            rate = "60.00";
          };
        };
      };

      "OneMonitor" = {
        fingerprint = {
          "DP-3" =
            "00ffffffffffff001e6d0c5cb326070003200103803c1978ea24e5ae5048a4240e5054256b007140818081c0a9c0b300d1c08100d1cfcd4600a0a0381f4030203a0059fe2000001a023a801871382d40582c450059fe2000001e000000fd00384b1e5a18010a202020202020000000fc004c4720554c545241574944450a0128020331f2230907074b100403011f1359125d5e5f830100006d030c002000b83c200060010203e305c000e60605014a4a56295900a0a038274030203a0059fe2000001a565e00a0a0a029503020350059fe2000001a000000ff003230334e54435a44533635390a000000000000000000000000000000000000000000000000af";
        };
        config = {
          "DP-1" = {
            enable = false;
          };
          "DP-2" = {
            enable = false;
          };
          "HDMI-1" = {
            enable = false;
          };
          "DP-3" = {
            crtc = 0;
            mode = "2560x1080";
            position = "0x0";
            primary = true;
            rate = "59.98";
          };
        };
      };
    };
  };

  xdg.configFile = {
    "autorandr/ThreeMonitors/setup".text = ''
      DP-1 00ffffffffffff004c2daa770101010110220103804627782aa723a8534495231a4b56bfef80714f81c0810081809500b300a9c00101023a801871382d40582c4500ba892100001e000000ff00200a2020202020202020202020000000fc004c53333244333978470a202020000000fd0030641e7d19000a202020202020011c02032a7149031213041f90400211230907078301000067030c0010000044681a000001013064f0e200cf2a4480a07038274030203500ba892100001a8d5780707038174030209800ba892100001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cf
      DP-3 00ffffffffffff001e6d0c5cb326070003200103803c1978ea24e5ae5048a4240e5054256b007140818081c0a9c0b300d1c08100d1cfcd4600a0a0381f4030203a0059fe2000001a023a801871382d40582c450059fe2000001e000000fd00384b1e5a18010a202020202020000000fc004c4720554c545241574944450a0128020331f2230907074b100403011f1359125d5e5f830100006d030c002000b83c200060010203e305c000e60605014a4a56295900a0a038274030203a0059fe2000001a565e00a0a0a029503020350059fe2000001a000000ff003230334e54435a44533635390a000000000000000000000000000000000000000000000000af
      HDMI-1 00ffffffffffff0006b3d227827c0000311e0103803c22782ae925a4554f9a260e5054bfef00d1c0b30095008180814081c0714f0101023a801871382d40582c450056502100001e000000ff004c434c4d54463033313837340a000000fd00304b185412000a202020202020000000fc004153555320564132374548450a01e002032b714f0102031112130414050e0f1d1e1f90230917078301000065030c001000681a00000101304be66842806a703827400820980456502100001a011d007251d01e206e28550056502100001e011d00bc52d01e20b828554056502100001e8c0ad090204031200c405500565021000018000000000000000000000000b7
    '';

    "autorandr/ThreeMonitors/config".text = ''
      output DP-2
      off
      output HDMI-1
      crtc 2
      mode 1920x1080
      pos 0x0
      rate 60.00
      x-prop-broadcast_rgb Automatic
      x-prop-colorspace Default
      x-prop-max_bpc 16
      x-prop-non_desktop 0
      x-prop-scaling_mode None
      x-prop-underscan off
      x-prop-underscan_hborder 0
      x-prop-underscan_vborder 0
      output DP-1
      crtc 0
      mode 1920x1080
      pos 1920x0
      primary
      rate 60.00
      x-prop-broadcast_rgb Automatic
      x-prop-colorspace Default
      x-prop-max_bpc 16
      x-prop-non_desktop 0
      x-prop-scaling_mode None
      x-prop-underscan off
      x-prop-underscan_hborder 0
      x-prop-underscan_vborder 0
      output DP-3
      crtc 1
      mode 2560x1080
      pos 1920x1080
      rate 59.98
      x-prop-broadcast_rgb Automatic
      x-prop-colorspace Default
      x-prop-max_bpc 10
      x-prop-non_desktop 0
      x-prop-scaling_mode None
      x-prop-underscan off
      x-prop-underscan_hborder 0
      x-prop-underscan_vborder 0
    '';
  };

  systemd.user = {
    services = {
      autorandr = {
        Unit = {
          Description = "Autorandr display change";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.autorandr}/bin/autorandr --change";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # Split out from autorandr.service: setting the wallpaper needs the
      # Dropbox mount to be up, but the rest of autorandr's postswitch hooks
      # (trayer, numlock, keyboard layout) don't and shouldn't fail just because
      # Dropbox is unreachable. Runs once at login (WantedBy) and is re-triggered
      # on every display change by the 10_setup_feh postswitch hook above.
      autorandr-wallpaper = {
        Unit = {
          Description = "Set desktop wallpaper from Dropbox backgrounds";
          After = [
            "graphical-session.target"
            "rclone-dropbox.service"
          ];
          Requires = [ "rclone-dropbox.service" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart =
            let
              script = pkgs.writeShellScript "autorandr-wallpaper" ''
                SELECTED_BACKGROUND_FILE="$HOME/.cache/background-picker/selected-background.txt"
                if [ -s "$SELECTED_BACKGROUND_FILE" ]; then
                  ${pkgs.feh}/bin/feh --no-fehbg --bg-max "$(cat "$SELECTED_BACKGROUND_FILE")"
                else
                  DROPBOX_LOCATION=$(find ~/Documents -type d -name Dropbox -print -quit)
                  BACKGROUNDS_DIR="$DROPBOX_LOCATION/Pictures/SharedBackgrounds"
                  PERSON_SPECIFIC="''${USER}Specific"
                  THEME_DIRS="$PERSON_SPECIFIC Default $(${pkgs.name-time-period}/bin/name_time_period)"
                  ${pkgs.feh}/bin/feh --no-fehbg --bg-max $(${pkgs.images-matching-subdirectories}/bin/images_matching_subdirectories --names-only --limit 4 $BACKGROUNDS_DIR $THEME_DIRS)
                fi
              '';
            in
            "${script}";
          RemainAfterExit = false;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # One half of the AND-gate for display-ready.target: marks "XMonad has
      # reached its startup hook this session" and, only once the other half
      # (autorandr-settled.service, set by the 15_start_display_ready postswitch
      # hook above) has also happened, starts the target. Using an AND instead
      # of trusting either trigger alone: XMonad's own spawn fires the moment
      # XMonad starts, which says nothing about whether autorandr has actually
      # finished settling the monitor layout; conversely autorandr's postswitch
      # firing says nothing about whether XMonad (which has to be up to pin
      # these apps' windows via manageHook) has actually started yet -- the two
      # events race each other at login with no inherent ordering between them.
      # Both markers are oneshot+RemainAfterExit and PartOf=graphical-session.target
      # so they reset on a real logout but survive an `xmonad --restart` within
      # the same session (where re-arming the gate and re-launching these apps
      # would be pointless churn).
      #
      # The AND is implemented as "set my own marker, then check if the other
      # one is already set" on both sides rather than systemd-level Requires=
      # (which would just force-start the other marker immediately, defeating
      # the point of waiting for a real external signal). Whichever side's
      # check runs second is guaranteed to observe the other's marker already
      # active, since each side's own marker-set is a blocking systemctl call
      # that completes strictly before that side's own check -- so exactly one
      # side ends up actually starting the target, regardless of which fires
      # first.
      xmonad-ready = {
        Unit = {
          Description = "Marker: XMonad has reached its startup hook this session";
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/true";
        };
      };

      autorandr-settled = {
        Unit = {
          Description = "Marker: autorandr has applied a profile this session";
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/true";
        };
      };
    };

    # Single gate for every GUI app whose window placement/geometry depends on
    # the monitor layout (TouchOSC, midi-staff-trainer, guitarix, obsidian,
    # qpwgraph, non-mixer-xt -- see their Unit comments -- plus midi-daemon,
    # which isn't a window itself but has to start between non-mixer-xt and
    # touchosc, both of which are gated here). Deliberately not WantedBy
    # anything: if they started at the same time as autorandr.service via
    # graphical-session.target like everything else, they'd race it exactly
    # like before. Instead this only ever starts once both xmonad-ready.service
    # and autorandr-settled.service above are active (see their comment for
    # why it's an AND of the two, not either alone). Once started, it's left
    # alone: per observation this race only happens at login, so there's no
    # postswitch hook to restart it -- a later monitor change shouldn't bounce
    # these apps. Any new app whose startup cares about the monitor layout
    # should join this target's Wants= rather than growing its own
    # autorandr.service After= -- that's what this exists to avoid having to
    # re-litigate per app.
    targets.display-ready = {
      Unit = {
        Description = "Display geometry settled -- safe to start apps that depend on it";
        After = [
          "xmonad-ready.service"
          "autorandr-settled.service"
        ];
        Wants = [
          "non-mixer-xt.service"
          "midi-daemon.service"
          # touchosc.service: disabled in non-fprice.nix (pins a CPU core
          # regardless of layout/backend/version), so left out here too --
          # otherwise this Wants a unit that no longer exists.
          "midi-staff-trainer.service"
          "guitarix.service"
          "obsidian.service"
          "qpwgraph.service"
        ];
      };
    };
  };
}
