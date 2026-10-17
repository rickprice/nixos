{ lib, rustPlatform, fetchCrate }:

rustPlatform.buildRustPackage {
  pname = "darktable-import-xmp";
  version = "0.2.0";

  src = fetchCrate {
    pname = "darktable-import-xmp";
    version = "0.2.0";
    hash = "sha256-qRDISxnLw4Ef8z3Y3a5J6FJ1qC4+58+N0RC3ZuiQcIc=";
  };

  cargoHash = "sha256-UtsGI4qzfj9tvEA0BBl+IUxs/OyInB6Y0xM0TcfXgwU=";

  meta = with lib; {
    description = "Import loose XMP sidecar files into Darktable's library database";
    homepage = "https://github.com/rickprice/darktable-import-xmp";
    license = licenses.bsd3;
    mainProgram = "darktable-import-xmp";
    platforms = platforms.linux;
  };
}
