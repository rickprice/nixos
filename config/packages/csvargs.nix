{ lib, rustPlatform, fetchFromGitHub, versionCheckHook }:

rustPlatform.buildRustPackage rec {
  pname = "csvargs";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "csvargs";
    rev = "v${version}";
    hash = "sha256-+ofM+nvmYyLTnwfDnDPTS/8/7ApKjLzhTCWZeQVF87I=";
  };

  cargoHash = "sha256-u8yVOcw8eL7VnfB4s9AX2fMIuhY5zmZWTnUDdtS05Rw=";

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = with lib; {
    description = "A command-line tool for processing CSV files with Jinja2 templates and executing commands on each row";
    homepage = "https://github.com/rickprice/csvargs";
    license = licenses.bsd3;
    mainProgram = "csvargs";
    platforms = platforms.linux;
  };
}
