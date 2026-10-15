{ lib, rustPlatform, fetchCrate }:

rustPlatform.buildRustPackage {
  pname = "markdown_timesheet";
  version = "0.9.0";

  src = fetchCrate {
    pname = "markdown_timesheet";
    version = "0.9.0";
    hash = "sha256-6R4wHSJnwUrV9fONnpHp4oBwmL+PCIGlv8YDyI3Wq2E=";
  };

  cargoHash = "sha256-6rQzgs4sFjG5wSNAqsE7iL9E7bhx9CoD87GEqefX/jY=";

  meta = with lib; {
    description = "A tool for processing markdown files to extract and format timesheet data";
    homepage = "https://crates.io/crates/markdown_timesheet";
    license = licenses.mit;
    mainProgram = "markdown_timesheet";
    platforms = platforms.linux;
  };
}
