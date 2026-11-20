{ pkgs, ... }:
{
  # fwork's Super I/O hwmon chip (nct6793, via the nct6775 driver) isn't bound
  # by default, and without it the BIOS's "Smart Power" curve is the only
  # thing driving the case fans, reacting to CPU temp only, not case/ambient.
  # ACPI reserves the chip's I/O range exclusively, so without this param the
  # driver can't claim it at all. it87 is kept alongside nct6775 as a
  # fallback for the wrong-chip case; it simply fails to bind harmlessly.
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  boot.kernelModules = [ "nct6775" "it87" ];

  # lm_sensors (`sensors`) is monitoring-only now: pwmconfig(8) confirmed the
  # chip's firmware/EC refuses manual PWM mode on every case-fan header
  # ("Manual control mode not supported"), so there is no OS-level case-fan
  # control path on this board. The only pwm pwmconfig could actually drive
  # was hwmon4/pwm1, which is the amdgpu GPU fan already managed by the GPU
  # driver's own curve, not a case fan. hardware.fancontrol is deliberately
  # never enabled here — pointing it at that pwm would just fight amdgpu.
  # Remaining option, if wanted later: check the BIOS's fan/Q-Fan menu for a
  # per-header temperature-source setting (e.g. chassis fan -> "System Temp"
  # instead of CPU) — untested, this board may not expose one.
  environment.systemPackages = [ pkgs.lm_sensors ];
}
