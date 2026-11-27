{
  lib,
  rustPlatform,
  fetchCrate,
  pkg-config,
  makeWrapper,
  libraw,
  ffmpeg-headless,
}:

rustPlatform.buildRustPackage rec {
  pname = "photo-splitter";
  version = "0.5.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-EFqF19feDfsC89Dd7oIKNM3xEGGnlP8vph5/WpxMe+k=";
  };

  cargoHash = "sha256-TsJHKcxfwYZrLVe7J3H48RuPDxR5TyOtkpHob9BcrSM=";

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
    makeWrapper
  ];
  buildInputs = [ libraw ];

  # libraw_r links libgomp, so by default each rayon worker thread's LibRaw
  # call spawns its own OpenMP thread team -- 12 rayon workers x ~12 OpenMP
  # threads each oversubscribes a 12-core machine ~12x. OMP_NUM_THREADS=1
  # leaves rayon's cross-file parallelism as the only parallelism layer.
  # --set-default so an explicit OMP_NUM_THREADS in the caller's environment
  # still wins.
  #
  # ffmpeg-headless (v0.2.0 added video-file QR-marker support) is a
  # *runtime* dependency only -- shelled out to, never linked -- so it
  # goes on PATH here rather than in buildInputs/nativeBuildInputs.
  # -headless to skip the GUI/X11/Qt deps the full ffmpeg package pulls
  # in, which this CLI tool never uses.
  postFixup = ''
    wrapProgram $out/bin/photo-splitter \
      --set-default OMP_NUM_THREADS 1 \
      --prefix PATH : "${lib.makeBinPath [ ffmpeg-headless ]}"
  '';

  meta = {
    description = "Splits a directory of time-ordered photos into per-shoot folders using QR-code marker frames";
    homepage = "https://github.com/rickprice/field-label-tools";
    license = lib.licenses.mit;
    mainProgram = "photo-splitter";
    platforms = lib.platforms.linux;
  };
}
