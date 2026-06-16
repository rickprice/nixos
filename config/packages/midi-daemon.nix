{ lib, rustPlatform, fetchFromGitHub, alsa-lib, pkg-config }:

rustPlatform.buildRustPackage {
  pname = "midi-daemon";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "midi-daemon";
    rev = "v0.5.0";
    hash = "sha256-t+ti4jWYB/2Awv4OpmTt9p6zXjjF9JcEPzYYsfubpXQ=";
  };

  cargoHash = "sha256-xKKa2Srm8/AGGECTVvqnnyZ1NxKVIEUWWpxulakiHvg=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ alsa-lib ];

  postInstall = ''
    install -Dm644 config.toml $out/share/doc/midi-daemon/config.toml

    for lua in routes.d/*.lua; do
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
