{ lib, rustPlatform, fetchCrate, versionCheckHook }:

rustPlatform.buildRustPackage rec {
  pname = "darktable-import-xmp";
  version = "0.2.1";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-BW22tnvjCKEqhmCEvD6x9agZbxkAz+yg/Z7NV830bUM=";
  };

  cargoHash = "sha256-rQF4DCNEdaNBWcdQ2XCeMmZ7qQ2TgEjfTAqzMQyToww=";

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = with lib; {
    description = "Import loose XMP sidecar files into Darktable's library database";
    homepage = "https://github.com/rickprice/darktable-import-xmp";
    license = licenses.bsd3;
    mainProgram = "darktable-import-xmp";
    platforms = platforms.linux;
  };
}
