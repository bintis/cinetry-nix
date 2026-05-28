{
  addDriverRunpath,
  alsa-lib,
  atk,
  autoPatchelfHook,
  cairo,
  dbus,
  dpkg,
  fetchurl,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  lib,
  libGL,
  libayatana-appindicator,
  libdbusmenu,
  libdrm,
  libepoxy,
  libgbm,
  libglvnd,
  libpulseaudio,
  libx11,
  libxcb,
  libxkbcommon,
  libmpv1,
  makeShellWrapper,
  pango,
  stdenv,
  wayland,

  # For custom command line arguments, e.g. "--enable-features=UseOzonePlatform"
  commandLineArgs ? "",
}:

let
  sources = {
    x86_64-linux = fetchurl {
      url = "https://github.com/gstory0404/Cinetry/releases/download/0.8.2/Cinetry_0.8.2%2B46_linux.deb";
      sha256 = "sha256-6US2qtNRempDB2CmikTWN1SNr3ahTrxeKrdJMz6HCOI=";
    };
  };
in
stdenv.mkDerivation {
  version = "0.8.2";
  pname = "cinetry";

  src =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  nativeBuildInputs = [
    autoPatchelfHook
    makeShellWrapper
    dpkg
  ];

  # autoPatchelfHook reads buildInputs for its system-library search path.
  # Bundled libs in /opt/cinetry/lib are added separately in preFixup.
  buildInputs = [
    alsa-lib
    atk
    cairo
    dbus
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libGL
    libayatana-appindicator
    libdbusmenu
    libdrm
    libepoxy
    libgbm
    libglvnd
    libpulseaudio
    libmpv1
    libx11
    libxcb
    libxkbcommon
    pango
    stdenv.cc.cc
    wayland
  ];

  dontUnpack = true;
  installPhase = ''
    runHook preInstall

    dpkg --fsys-tarfile $src | tar --extract
    mkdir -p $out
    mv usr/share $out/
    mv opt/ $out/

    # The upstream .desktop hardcodes /opt/cinetry/cinetry and
    # /usr/share/icons/logo.png. Point both at our store paths and switch
    # the icon to a themed name so hicolor picks it up.
    substituteInPlace $out/share/applications/cinetry.desktop \
      --replace-fail /opt/cinetry/cinetry $out/opt/cinetry/cinetry \
      --replace-fail /usr/share/icons/logo.png cinetry

    install -Dm644 $out/share/icons/logo.png \
      $out/share/icons/hicolor/72x72/apps/cinetry.png
    rm $out/share/icons/logo.png

    # wrapProgram before autoPatchelfHook runs in fixupPhase — the wrapper
    # script gets installed at $out/opt/cinetry/cinetry and the real ELF is
    # renamed to .cinetry-wrapped, which autoPatchelf then patches.
    # XDG_DATA_DIRS lets GTK find icon themes and GSettings schemas;
    # LD_LIBRARY_PATH must put /opt/cinetry/lib first so transitive deps
    # of bundled plugins (libmdk → libavformat from libffmpeg.so.8) resolve
    # against the bundled versions — relying on RUNPATH alone makes some
    # plugins pick up nix-store libs and breaks Cinetry's init order, the
    # same way AppImage works by prepending $APPDIR/usr/bin/lib.
    # driverLink/lib also goes in for mdk access to host GPU drivers
    # (Mesa libGL, VAAPI, etc.).
    wrapProgram $out/opt/cinetry/cinetry \
      --prefix XDG_DATA_DIRS    :  "$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH" \
      --prefix LD_LIBRARY_PATH  :  ${addDriverRunpath.driverLink}/lib \
      --prefix LD_LIBRARY_PATH  :  "$out/opt/cinetry/lib" \
      ${lib.optionalString (
        commandLineArgs != ""
      ) "--add-flags ${lib.escapeShellArg commandLineArgs}"}

    mkdir -p $out/bin
    ln -s $out/opt/cinetry/cinetry $out/bin/cinetry

    runHook postInstall
  '';

  # Bundled libs in /opt/cinetry/lib (libmdk, libffmpeg, vendored libc++,
  # Flutter plugin shims) need to be on autoPatchelf's search path so the
  # main binary's NEEDED entries can resolve to siblings.
  preFixup = ''
    addAutoPatchelfSearchPath $out/opt/cinetry/lib
  '';

  dontStrip = true;

  meta = {
    description = "Cinetry Player";
    homepage = "https://github.com/gstory0404/Cinetry";
    downloadPage = "https://github.com/gstory0404/Cinetry/releases";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "cinetry";
  };
}
