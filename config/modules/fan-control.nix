{ pkgs, ... }:
{
  # fwork's Super I/O hwmon chip (case fan headers) isn't bound by default:
  # with no sensor driver loaded, the BIOS's own "Smart Power" curve is the
  # only thing driving the case fans, and it only reacts to CPU temp, not
  # case/ambient. nct6775 and it87 are the two likely drivers for this board;
  # whichever doesn't match simply fails to bind (harmless). ACPI reserves
  # the chip's I/O range exclusively, so without this param neither driver
  # can claim it at all.
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  boot.kernelModules = [ "nct6775" "it87" ];

  environment.systemPackages = [ pkgs.lm_sensors ];

  # hardware.fancontrol.enable/config intentionally left unset here: `config`
  # must be the literal output of pwmconfig(8), which depends on which chip
  # above actually bound and which pwm* output maps to which physical fan.
  # After rebuilding and rebooting into this:
  #   sudo sensors-detect   # confirm a chip beyond coretemp/acpitz/amdgpu shows up
  #   sudo pwmconfig        # interactively maps pwm outputs to fans, writes /etc/fancontrol
  # then bring the resulting config back here and set hardware.fancontrol.enable = true.
}
