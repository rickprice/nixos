{ lib, rustPlatform, fetchCrate }:

rustPlatform.buildRustPackage {
  pname = "markdown_timesheet";
  version = "0.8.0";

  src = fetchCrate {
    pname = "markdown_timesheet";
    version = "0.8.0";
    hash = "sha256-u26uUT8W62vJU7yf+eDFQDLOA/qIMZugy8tn6Eixpw4=";
  };

  cargoHash = "sha256-wHjm6hiBvyEZSx12kvWZOn6myyouTp/gIAYitrDSS3o=";

  meta = with lib; {
    description = "A tool for processing markdown files to extract and format timesheet data";
    homepage = "https://crates.io/crates/markdown_timesheet";
    license = licenses.mit;
    mainProgram = "markdown_timesheet";
    platforms = platforms.linux;
  };
}
