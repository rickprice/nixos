_:

{
  xdg = {
    configFile."mimeapps.list".force = true;
    dataFile."applications/mimeapps.list".force = true;

    mimeApps = {
      enable = true;
      defaultApplications = {
        "image/bmp" = "feh.desktop";
        "image/gif" = "feh.desktop";
        "image/heic" = "feh.desktop";
        "image/jpeg" = "feh.desktop";
        "image/jpg" = "feh.desktop";
        "image/pjpeg" = "feh.desktop";
        "image/png" = "feh.desktop";
        "image/tiff" = "feh.desktop";
        "image/webp" = "feh.desktop";
        "image/x-bmp" = "feh.desktop";
        "image/x-pcx" = "feh.desktop";
        "image/x-png" = "feh.desktop";
        "image/x-portable-anymap" = "feh.desktop";
        "image/x-portable-bitmap" = "feh.desktop";
        "image/x-portable-graymap" = "feh.desktop";
        "image/x-portable-pixmap" = "feh.desktop";
        "image/x-tga" = "feh.desktop";
        "image/x-xbitmap" = "feh.desktop";
        "application/pdf" = "atril.desktop";
        "application/x-bzpdf" = "atril.desktop";
        "application/x-gzpdf" = "atril.desktop";
        "application/x-xzpdf" = "atril.desktop";
        "application/zip" = "org.gnome.FileRoller.desktop";
        "application/x-zip" = "org.gnome.FileRoller.desktop";
        "application/x-zip-compressed" = "org.gnome.FileRoller.desktop";
        "application/x-tar" = "org.gnome.FileRoller.desktop";
        "application/x-bzip2" = "org.gnome.FileRoller.desktop";
        "application/x-gzip" = "org.gnome.FileRoller.desktop";
        "application/x-xz" = "org.gnome.FileRoller.desktop";
        "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
        "application/x-rar" = "org.gnome.FileRoller.desktop";
        "application/x-rar-compressed" = "org.gnome.FileRoller.desktop";
      };
    };
  };
}
