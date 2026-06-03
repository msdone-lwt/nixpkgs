{
  electron,
  fetchFromGitHub,
  imagemagick,
  lib,
  makeDesktopItem,
  makeWrapper,
  nodejs,
  pnpm,
  fetchPnpmDeps,
  pnpmConfigHook,
  stdenv,
  pkg-config,
  vips,
}:
stdenv.mkDerivation rec {
  pname = "folo";
  version = "1.9.0";

  src = fetchFromGitHub {
    owner = "RSSNext";
    repo = "Folo";
    tag = "desktop/v${version}";
    hash = "sha256-VrKWqqXzdEOfl8E069eZCeI5agxWKmRMW6ziGqURuHc=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    makeWrapper
    imagemagick
    pkg-config
  ];

  buildInputs = [
    vips
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-uj7xyh+U4OHn6J+jhoPaEOYwOLinRAj5CbWZYPgG6zI=";
  };

  pnpmFlags = [
    "--filter=./apps/desktop..."
    "--filter=./packages/..."
    "--ignore-scripts"
    "--child-concurrency=1"
    "--network-concurrency=1"
  ];

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    SHARP_IGNORE_GLOBAL_LIBVIPS = "1";

    VITE_WEB_URL = "https://app.folo.is";
    VITE_API_URL = "https://api.folo.is";
    VITE_OPENPANEL_API_URL = "https://openpanel.folo.is/api";

    VITE_FIREBASE_CONFIG = builtins.toJSON {
      apiKey = "AIzaSyBpGB2C2Vz-9ktivqVkW7uTtVopNh3ELvo";
      authDomain = "diygod-folo.firebaseapp.com";
      projectId = "diygod-folo";
      storageBucket = "diygod-folo.firebasestorage.app";
      messagingSenderId = "992336953943";
      appId = "1:992336953943:web:998aae576c8bc77dc11912";
      measurementId = "G-HS4SF4GHWG";
    };
  };

  dontCheckForBrokenSymlinks = true;

  desktopItem = makeDesktopItem {
    name = "folo";
    desktopName = "Folo";
    comment = "Next generation information browser";
    icon = "follow";
    exec = "follow";
    categories = [ "Utility" ];
    mimeTypes = [ "x-scheme-handler/follow" ];
  };

  icon = src + "/apps/desktop/resources/icon.png";

  buildPhase = ''
    runHook preBuild

    pnpm run build:packages

    cd apps/desktop
    pnpm --offline --no-inline-css build:electron-vite
    cd ../..

    CI=true pnpm --ignore-scripts prune --prod
    find node_modules/.bin -xtype l -delete

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/{applications,follow}
    cp -r . $out/share/follow
    rm -rf $out/share/follow/{.vscode,.github}

    makeWrapper "${electron}/bin/electron" "$out/bin/follow" \
      --inherit-argv0 \
      --add-flags $out/share/follow/apps/desktop \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

    install -m 444 -D "${desktopItem}/share/applications/"* \
        -t $out/share/applications/

    for size in 16 24 32 48 64 128 256 512; do
      mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
      convert -background none -resize "$size"x"$size" ${icon} $out/share/icons/hicolor/"$size"x"$size"/apps/follow.png
    done

    runHook postInstall
  '';

  meta = {
    description = "Next generation information browser";
    homepage = "https://github.com/RSSNext/Folo";
    changelog = "https://github.com/RSSNext/Folo/releases/tag/${src.tag}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ iosmanthus ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "follow";
  };
}
