{ lib, rustPlatform, fetchCrate }:

rustPlatform.buildRustPackage {
  pname = "images_matching_subdirectories";
  version = "0.1.0";

  src = fetchCrate {
    pname = "images_matching_subdirectories";
    version = "0.1.0";
    hash = "sha256-yRyIsrWROR6nBBCVUQE0OCliXdB3gZRLDGaLVnAVyTg=";
  };

  cargoHash = "sha256-izCylpt8V0+2s2XqVBckvSIlj6k0Q6H1R+6dJqkkr+k=";

  meta = with lib; {
    description = "Find images inside named subdirectories of a parent directory";
    homepage = "https://github.com/rickprice/images_matching_subdirectories";
    license = licenses.mit;
    mainProgram = "images_matching_subdirectories";
    platforms = platforms.linux;
  };
}
