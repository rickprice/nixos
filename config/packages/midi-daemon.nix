{ lib, rustPlatform, fetchFromGitHub, alsa-lib, pkg-config }:

rustPlatform.buildRustPackage {
  pname = "midi-daemon";
  version = "0.4.9";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "midi-daemon";
    rev = "v0.4.9";
    hash = "sha256-+fAyRk0x585edgKg/yG24AVdHPEJW/2FqHY4klZjuJI=";
  };

  cargoHash = "sha256-DsGHopJb/DieEXhPfXm3wGQb14zosY5jYetoDmOo4Uk=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ alsa-lib ];

  postInstall = ''
    install -Dm644 systemd/midi-daemon-system.service \
      $out/lib/systemd/system/midi-daemon.service
    substituteInPlace $out/lib/systemd/system/midi-daemon.service \
      --replace-fail /usr/local/bin/midi-daemon $out/bin/midi-daemon

    install -Dm644 config.toml $out/share/doc/midi-daemon/config.toml

    for lua in routes.d/*.lua; do
      install -Dm644 "$lua" $out/share/doc/midi-daemon/examples/"$lua"
    done

    for tosc in TouchOSC/*.tosc; do
      install -Dm644 "$tosc" $out/share/doc/midi-daemon/examples/"$tosc"
    done
  '';

  meta = with lib; {
    description = "A Lua-scriptable MIDI routing daemon";
    homepage = "https://github.com/rickprice/midi-daemon";
    license = licenses.bsd3;
    mainProgram = "midi-daemon";
    platforms = platforms.linux;
  };
}
