{ lib, rustPlatform, fetchCrate }:

rustPlatform.buildRustPackage {
  pname = "name_time_period";
  version = "0.4.0";

  src = fetchCrate {
    pname = "name_time_period";
    version = "0.4.0";
    hash = "sha256-Dk32hHiOGpX7zoFycEcqkJE948pMUxiMurW23//KG/U=";
  };

  cargoHash = "sha256-wbXcSeevRQT3cBxbV/ArzlZS43xfKA5FoiXZ6v0sogs=";

  meta = with lib; {
    description = "Name the time period a date is in, configuration is supported";
    homepage = "https://github.com/rickprice/NameTimePeriods";
    license = licenses.mit;
    mainProgram = "name_time_period";
    platforms = platforms.linux;
  };
}
