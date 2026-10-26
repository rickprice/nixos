{ lib, ... }:

{
  # thumbnail_max is in KB; the default 2048 (2 MB) blocks modern camera JPEGs
  # (5–15 MB) and CR2 RAW files (45–55 MB).  xdg.configFile is wrong here
  # because it creates a read-only symlink; pcmanfm atomically replaces it with
  # a new regular file containing defaults on every write.  A home.activation
  # script instead patches/creates a regular writable file that pcmanfm can
  # round-trip correctly, preserving the 100 MB ceiling we set.
  home.activation.libfmThumbnailMax = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    libfm_conf="$HOME/.config/libfm/libfm.conf"
    [ -L "$libfm_conf" ] && rm -f "$libfm_conf"
    mkdir -p "$HOME/.config/libfm"
    if [ -f "$libfm_conf" ] && grep -q "^thumbnail_max=" "$libfm_conf"; then
      sed -i 's/^thumbnail_max=.*/thumbnail_max=102400/' "$libfm_conf"
    elif [ -f "$libfm_conf" ]; then
      sed -i '/^\[config\]/a thumbnail_max=102400' "$libfm_conf"
    else
      printf '[config]\nthumbnail_local=1\nthumbnail_max=102400\n' > "$libfm_conf"
    fi
  '';
}
