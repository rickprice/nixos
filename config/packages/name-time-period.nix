{ lib, rustPlatform, fetchCrate }:

rustPlatform.buildRustPackage {
  pname = "name_time_period";
  version = "0.3.1";

  src = fetchCrate {
    pname = "name_time_period";
    version = "0.3.1";
    hash = "sha256-WOM63AF/GAdCXNdbo1S6UDZs3fh00ckXNlaybSSBJHs=";
  };

  cargoHash = "sha256-U7JAvCl30v5cicHnsNlO0QOsZ5rEmlTUVJ0xjwHe6MY=";

  meta = with lib; {
    description = "Name the time period a date is in, configuration is supported";
    homepage = "https://github.com/rickprice/NameTimePeriods";
    license = licenses.mit;
    mainProgram = "name_time_period";
    platforms = platforms.linux;
  };
}
