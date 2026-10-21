{ lib, rustPlatform, fetchCrate, versionCheckHook }:

rustPlatform.buildRustPackage rec {
  pname = "markdown_timesheet";
  version = "0.9.1";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-pKEVTn9Fngppn7y77MZIUlFHPLyaHDTN/pcuocX7Qt8=";
  };

  cargoHash = "sha256-5JKDW+/qmp9UIAKh17dRprGo4jkfsFh7qYQWgO0n+9Y=";

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = with lib; {
    description = "A tool for processing markdown files to extract and format timesheet data";
    homepage = "https://crates.io/crates/markdown_timesheet";
    license = licenses.mit;
    mainProgram = "markdown_timesheet";
    platforms = platforms.linux;
  };
}
