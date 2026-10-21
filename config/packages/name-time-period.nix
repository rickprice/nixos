{ lib, rustPlatform, fetchCrate, versionCheckHook }:

rustPlatform.buildRustPackage rec {
  pname = "name_time_period";
  version = "0.4.1";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-br96Iffn+XPWhlD4qh0OF/K6clc2YV0D1KMJGXDlhR8=";
  };

  cargoHash = "sha256-iWLxkqrd7j3Imno5xOm9vHwS4VZq7D3h2deK6Smnmf8=";

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = with lib; {
    description = "Name the time period a date is in, configuration is supported";
    homepage = "https://github.com/rickprice/NameTimePeriods";
    license = licenses.mit;
    mainProgram = "name_time_period";
    platforms = platforms.linux;
  };
}
