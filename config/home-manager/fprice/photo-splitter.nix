_:

{
  xdg.configFile."photo-splitter/config.toml".text = ''
    # photo-splitter configuration.
    #
    # tag_prefix: Darktable hierarchical tag prefix applied to every photo's
    # generated XMP sidecar (e.g. "PricePixel" tags a photo
    # "PricePixel|Project|...", "PricePixel|Location|...", etc.). Override
    # per-run with --tag-prefix, or point at a different file with --config.
    tag_prefix = "PricePixel"
    default_client = "PricePixel"
  '';
}
