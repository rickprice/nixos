{ lib, pkgs, ... }:

{
  # Chrome on Linux only reads managed policies from /etc/opt/chrome/policies/
  # (system-wide), so per-user settings must go through the Preferences file.
  home.activation.setChromeDownloadDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    prefFile="$HOME/.config/google-chrome/Default/Preferences"
    downloadDir="/home/fprice/Documents/Personal/Dropbox/FrederickDocuments/DropBoxDownloads"
    # Chrome holds its own in-memory copy of this file and flushes it back to
    # disk on its own schedule (tab close, settings change, clean exit). An
    # external rewrite while it's running either goes unnoticed until Chrome
    # itself writes next (silently clobbering this edit) or races a Chrome
    # write mid-flight. Skip entirely when Chrome is running; this activation
    # reruns on every switch, so it'll catch up next time Chrome isn't open.
    if ${pkgs.procps}/bin/pgrep -x chrome >/dev/null || ${pkgs.procps}/bin/pgrep -f google-chrome >/dev/null; then
      echo "Chrome is running; skipping Preferences rewrite (will retry on the next switch)."
    elif [ -f "$prefFile" ]; then
      if [ "$(${pkgs.jq}/bin/jq -r '.download.default_directory // ""' "$prefFile")" != "$downloadDir" ]; then
        tmp=$(${pkgs.coreutils}/bin/mktemp)
        ${pkgs.jq}/bin/jq --arg dir "$downloadDir" '.download.default_directory = $dir' "$prefFile" > "$tmp" \
          && ${pkgs.coreutils}/bin/mv "$tmp" "$prefFile"
      fi
    else
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$prefFile")"
      ${pkgs.jq}/bin/jq -n --arg dir "$downloadDir" '{"download":{"default_directory":$dir}}' > "$prefFile"
    fi
  '';
}
