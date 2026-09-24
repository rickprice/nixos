{ lib, rustPlatform, fetchCrate }:

rustPlatform.buildRustPackage {
  pname = "images_matching_subdirectories";
  version = "0.2.0";

  src = fetchCrate {
    pname = "images_matching_subdirectories";
    version = "0.2.0";
    hash = "sha256-ERtYiaLBpiuVSenF5mquCk981X4Y/tJ23q+OyYbDEVM=";
  };

  cargoHash = "sha256-mmy68kC7BY2t8wtq+lKNWtmxPEq49psZm+t1Lb8wCP8=";

  meta = with lib; {
    description = "Find images inside named subdirectories of a parent directory";
    homepage = "https://github.com/rickprice/images_matching_subdirectories";
    license = licenses.mit;
    mainProgram = "images_matching_subdirectories";
    platforms = platforms.linux;
  };
}
