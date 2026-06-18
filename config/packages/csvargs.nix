{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname = "csvargs";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "csvargs";
    rev = "v0.3.1";
    hash = "sha256-hApLMVWIQTgNYlA+9c/9jtJxXIKS1XorXHkV79mkOpk=";
  };

  cargoHash = "sha256-Siz+BCm1RJhwxchcLPzAWq2txSqzfxfbJ4ePp/Ilroc=";

  meta = with lib; {
    description = "A command-line tool for processing CSV files with Jinja2 templates and executing commands on each row";
    homepage = "https://github.com/rickprice/csvargs";
    license = licenses.bsd3;
    mainProgram = "csvargs";
    platforms = platforms.linux;
  };
}
