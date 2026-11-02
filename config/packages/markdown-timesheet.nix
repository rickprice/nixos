{
  lib,
  rustPlatform,
  fetchCrate,
  versionCheckHook,
}:

rustPlatform.buildRustPackage rec {
  pname = "markdown_timesheet";
  version = "0.9.3";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-LP094hl42d67SafBdW901srQTQGoRiL4IORkbB6yXHQ=";
  };

  cargoHash = "sha256-mCKS8u7LiGEw0jF/PqvaKBpcNMohWNE9PRB4i1n/27g=";

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
