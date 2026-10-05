{ lib, rustPlatform, fetchFromGitHub, alsa-lib, pkg-config }:

rustPlatform.buildRustPackage {
  pname = "midi-daemon";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "midi-daemon";
    rev = "v0.8.0";
    hash = "sha256-Fdhxq+g1xTra3FGeRaV33B1j+XU6lOYQposnpPoVd4Y=";
  };

  cargoHash = "sha256-zmrhkC8/Rndkq/Pfcu4aYr9IDoyR2EH9GkYl5tIW190=";

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
