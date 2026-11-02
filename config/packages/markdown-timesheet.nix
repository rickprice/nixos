{
  lib,
  rustPlatform,
  fetchCrate,
  versionCheckHook,
}:

rustPlatform.buildRustPackage rec {
  pname = "markdown_timesheet";
  version = "0.9.2";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-eLC0Rm05i/Y9zEYM/pic29afSMtpTV+1NRdS87OhUVM=";
  };

  cargoHash = "sha256-lWzkfdcYkv0mttQsNeshewVz4iCudsFBCb4x8nriQGU=";

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
