{ lib, rustPlatform, fetchFromGitHub, alsa-lib, pkg-config }:

rustPlatform.buildRustPackage {
  pname = "midi-daemon";
  version = "0.7.3";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "midi-daemon";
    rev = "v0.7.3";
    hash = "sha256-YZwtqN/HMPWfBkuZ/2K0IDC6VCEpEyYcs12+6ZBymDU=";
  };

  cargoHash = "sha256-tQdxglHo4vgYKT4pj1gqckqoMxMdsArN5B26KyujXQk=";

  # Timer tests spawn real-time threads that time out in the Nix sandbox
  doCheck = false;

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
