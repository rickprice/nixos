owner:
{ ... }:
{
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Without this, the GUI/CLI can't use polkit-based system authentication
    # (unlock with the login password instead of/alongside the 1Password
    # master password).
    polkitPolicyOwners = [ owner ];
  };
}
