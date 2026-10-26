_:

{
  programs.plasma = {
    enable = true;

    kscreenlocker = {
      autoLock = true;
      timeout = 120; # lock after 2 hours of inactivity (minutes)
    };

    powerdevil.AC = {
      displayBrightness = 40;
      turnOffDisplay.idleTimeout = 3600; # turn off screen after 1 hour (seconds)
      autoSuspend.action = "nothing"; # disable automatic sleep/hibernate
    };
  };
}
