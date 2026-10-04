# vim: set ts=2 sw=2 et:
{ pkgs, ... }:

{
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  users.users.fprice.extraGroups = [ "libvirtd" ];

  environment.systemPackages = with pkgs; [
    qemu
  ];
}
