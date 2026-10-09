{ lib, rustPlatform, fetchFromGitHub, alsa-lib, pkg-config }:

rustPlatform.buildRustPackage {
  pname = "midi-daemon";
  version = "0.9.4";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "midi-daemon";
    rev = "v0.9.4";
    hash = "sha256-j4mA9vkkCtuz7jxZLriNMGWlEPwKPVM51wAL6zf4mWw=";
  };

  cargoHash = "sha256-eVLsHl5RWbUz/ofkrj3gZJwNU0h7olh18k9XJKqYiSw=";

  # Timer tests spawn real-time threads that time out in the Nix sandbox
  doCheck = false;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ alsa-lib ];

  postInstall = ''
    install -Dm644 config.toml $out/share/doc/midi-daemon/config.toml

    # find, not a routes.d/*.lua glob: routes.d/lib/ holds shared helpers
    # (e.g. nmxt.lua) that a flat glob wouldn't reach.
    find routes.d -name '*.lua' -print0 | while IFS= read -r -d $'\0' lua; do
      install -Dm644 "$lua" $out/share/doc/midi-daemon/examples/"$lua"
    done

    for tosc in TouchOSC/*.tosc; do
      install -Dm644 "$tosc" $out/share/doc/midi-daemon/examples/"$tosc"
    done
  '';

  meta = with lib; {
    description = "A Lua-scriptable MIDI routing daemon for Linux";
    homepage = "https://github.com/rickprice/midi-daemon";
    license = licenses.bsd3;
    mainProgram = "midi-daemon";
    platforms = platforms.linux;
  };
}
