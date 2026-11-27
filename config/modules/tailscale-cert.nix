# vim: set ts=2 sw=2 et:
# Tailscale can issue a real, publicly-trusted Let's Encrypt certificate for
# this host's MagicDNS name (fwork.<tailnet>.ts.net) with no manual ACME/DNS
# setup of our own -- Tailscale proves domain ownership itself. This needs
# "HTTPS Certificates" turned on once for the tailnet at
# https://login.tailscale.com/admin/dns (a one-time account setting, not
# something this config can do).
#
# This only issues/renews the cert to disk at /var/lib/tailscale-certs. The
# webapp that actually serves over it (Axum + rustls) should depend on
# tailscale-cert.service and read cert.pem/key.pem from there once that
# service exists -- not written here since there's no webapp unit yet to
# wire a restart-on-renew hook into.
{ pkgs, ... }:
{
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
