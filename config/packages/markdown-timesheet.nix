{
  lib,
  rustPlatform,
  fetchCrate,
  versionCheckHook,
}:

rustPlatform.buildRustPackage rec {
  pname = "markdown_timesheet";
  version = "0.9.4";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-l04jLMI2ZtDS/v+58QXsh1rv5LC0NcNElunOuf6efvk=";
  };

  cargoHash = "sha256-maYB0q4Lf6ozAMNel1Q9Z8BI8l6F1VgkZa6Zi2PHUew=";

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
