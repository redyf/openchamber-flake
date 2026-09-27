{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  stdenv,
}:

let
  pname = "openchamber";
  sources = import ./sources.nix;
  inherit (sources) version;

  # Upstream uses "arm64" and "x86_64" in the asset names.
  assetArch =
    {
      x86_64-linux = "x86_64";
      aarch64-linux = "arm64";
    }
    .${stdenv.hostPlatform.system}
      or (throw "openchamber: unsupported system ${stdenv.hostPlatform.system}");

  src = fetchurl {
    url = "https://github.com/openchamber/openchamber/releases/download/v${version}/OpenChamber-${version}-linux-${assetArch}.AppImage";
    hash = sources.hashes.${stdenv.hostPlatform.system};
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop

    # Upstream's AppImage entry is `Exec=AppRun --no-sandbox %U`, but the
    # AppImage's chrome-sandbox is not setuid, and Nix users have unprivileged
    # user namespaces, which Chromium uses for its namespace sandbox.
    sed -i -E 's|^Exec=AppRun.*$|Exec=${pname} %U|' $out/share/applications/${pname}.desktop

    # Upstream ships the icon outside hicolor's apps/ directory.
    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/scalable/${pname}.svg \
      $out/share/icons/hicolor/scalable/apps/${pname}.svg

    wrapProgram $out/bin/${pname} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Agentic development environment based on the OpenCode AI agent";
    longDescription = ''
      OpenChamber is a workspace for running and reviewing AI coding work on
      desktop, web, VS Code, and mobile. This package repackages the official
      Electron desktop AppImage, which bundles the matching OpenCode CLI.
    '';
    homepage = "https://openchamber.dev/";
    changelog = "https://github.com/openchamber/openchamber/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
