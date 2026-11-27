# vim: set ts=2 sw=2 et:
# Tailscale can issue a real, publicly-trusted Let's Encrypt certificate for
# this host's MagicDNS name (fwork.<tailnet>.ts.net) with no manual ACME/DNS
# setup of our own -- Tailscale proves domain ownership itself. This needs
# "HTTPS Certificates" turned on once for the tailnet at
# https://login.tailscale.com/admin/dns (a one-time account setting, not
# something this config can do).
#
# This issues/renews the cert to disk at /var/lib/tailscale-certs, group-reads
# the key out to the "tailscale-certs" group (the key starts out root-only;
# the webapp in media-calendar-manager.nix joins this group to read it without
# running as root), and restarts the webapp after each renewal so it picks up
# the new files.
{ pkgs, ... }:
{
  users.groups.tailscale-certs = { };

  systemd.services.tailscale-cert = {
    description = "Issue/renew this host's Tailscale HTTPS certificate";
    after = [ "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "tailscale-certs";
      ExecStart = pkgs.writeShellScript "tailscale-cert-renew" ''
        set -euo pipefail
        dns_name=$(${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq -r '.Self.DNSName | rtrimstr(".")')
        ${pkgs.tailscale}/bin/tailscale cert \
          --cert-file /var/lib/tailscale-certs/cert.pem \
          --key-file /var/lib/tailscale-certs/key.pem \
          "$dns_name"
      '';
      # The cert is public by nature, but the key defaults to root-only
      # (0600). Group-read it so the webapp can load it without running as
      # root, then restart the webapp so a renewed cert actually gets used.
      # try-restart (not restart): a no-op if the webapp unit isn't active,
      # and `|| true` keeps a future removal of that unit from breaking this
      # timer. --no-block is load-bearing, not just a nicety: on a switch
      # that activates both units for the first time together, a *blocking*
      # try-restart here deadlocks against media-calendar-manager.service's
      # own start job, which is ordered to wait on this unit finishing.
      ExecStartPost = pkgs.writeShellScript "tailscale-cert-post" ''
        set -euo pipefail
        chgrp tailscale-certs /var/lib/tailscale-certs/key.pem
        chmod 640 /var/lib/tailscale-certs/key.pem
        ${pkgs.systemd}/bin/systemctl --no-block try-restart media-calendar-manager.service || true
      '';
    };
  };

  systemd.timers.tailscale-cert = {
    description = "Daily renewal check for the Tailscale HTTPS certificate";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
