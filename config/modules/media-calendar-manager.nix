# vim: set ts=2 sw=2 et:
# Runs the Axum webapp (media-calendar-manager, checked out under fprice's
# personal_repo) as a dedicated, unprivileged systemd service, serving HTTPS
# directly via rustls using the cert tailscale-cert.nix issues to
# /var/lib/tailscale-certs.
#
# DB access: a Postgres role of the same name as the OS user, so the
# postgresql module's default pg_hba.conf ("local all all peer") authenticates
# it over the Unix socket with no password anywhere.
#
# Not Nix-packaged: this just execs the binary from a normal `cargo build
# --release` in the checkout. Re-running that build and `systemctl restart
# media-calendar-manager` is how a code change gets deployed -- this is a
# personal dev webapp, not something that needs a reproducible Nix derivation
# of the Rust build.
_:
let
  projectDir = "/home/fprice/Documents/Personal/personal_repo/media-calendar-manager";
in
{
  users.groups.media_calendar_manager = { };
  users.users.media_calendar_manager = {
    isSystemUser = true;
    group = "media_calendar_manager";
    extraGroups = [ "tailscale-certs" ];
    description = "media-calendar-manager webapp service account";
  };

  # /home/fprice is 0700, so media_calendar_manager can't otherwise traverse
  # into it to exec the built binary. This grants that one user execute-only
  # (traversal) access to that one directory -- everything below it is
  # already 0755, and this doesn't grant read/list on /home/fprice itself.
  #
  # The explicit mask entry is load-bearing: /home/fprice's group permission
  # bits are `---`, so the ACL mask defaults to `---` too, which silently caps
  # the named-user entry's effective permission to `---` regardless of what
  # it says -- `getfacl` showed exactly this ("u:media_calendar_manager:--x
  # #effective:---"). Raising the mask to `x` is what actually makes the
  # entry effective.
  systemd.tmpfiles.rules = [
    "A+ /home/fprice - - - - u:media_calendar_manager:X,m::x"
  ];

  services.postgresql = {
    ensureDatabases = [ "media_calendar_manager" ];
    ensureUsers = [
      {
        name = "media_calendar_manager";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.media-calendar-manager = {
    description = "Media Calendar Manager web app";
    after = [
      "postgresql.service"
      "tailscale-cert.service"
      "network-online.target"
    ];
    requires = [ "postgresql.service" ];
    wants = [
      "tailscale-cert.service"
      "network-online.target"
    ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      DATABASE_URL = "postgres:///media_calendar_manager?host=/run/postgresql";
      TLS_CERT_PATH = "/var/lib/tailscale-certs/cert.pem";
      TLS_KEY_PATH = "/var/lib/tailscale-certs/key.pem";
    };

    serviceConfig = {
      Type = "simple";
      User = "media_calendar_manager";
      Group = "media_calendar_manager";
      WorkingDirectory = projectDir;
      ExecStart = "${projectDir}/target/release/media-calendar-manager";
      Restart = "on-failure";
      RestartSec = 5;

      # Binding :443 as a non-root user needs this one capability.
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      NoNewPrivileges = true;
    };
  };
}
