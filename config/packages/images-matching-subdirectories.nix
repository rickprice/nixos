{ lib, rustPlatform, fetchCrate, versionCheckHook }:

rustPlatform.buildRustPackage rec {
  pname = "images_matching_subdirectories";
  version = "0.2.1";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-uLDoYYRTEbP3SFViQpZxxHcv/k6sY+E85fwfH8TlTjk=";
  };

  cargoHash = "sha256-+yptyttKyXjahSzP0EGHYtZuyjKaljjMhamVv6oeBaY=";

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = with lib; {
    description = "Find images inside named subdirectories of a parent directory";
    homepage = "https://github.com/rickprice/images_matching_subdirectories";
    license = licenses.mit;
    mainProgram = "images_matching_subdirectories";
    platforms = platforms.linux;
  };
}
