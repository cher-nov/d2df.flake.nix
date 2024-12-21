{
  # Example:
  # {"arm64-v8a" = { isWindows = false; sharedLibraries = [SDL2_custom enet_custom]; doom2df = .../null; editor = .../null; asLibrary = false; prefix = "arm64-v8a"}; }
  byArchPkgsAttrs,
  stdenvNoCC,
  gnused,
  gawk,
  zip,
  findutils,
  outils,
  lib,
}:
stdenvNoCC.mkDerivation {
  pname = "d2df-bundle";
  version = "git";
  phases = ["buildPhase" "installPhase"];

  nativeBuildInputs = [gawk gnused zip findutils outils];

  buildPhase = let
    copyLibraries = archAttrs: let
      i = lib.map (library:
        ''
          [ -d "${library}/lib" ] && find -L ${library}/lib -iname '*.so' -type f -exec cp {} ${archAttrs.prefix} \;
        ''
        + lib.optionalString archAttrs.isWindows ''
          [ -d "${library}/bin" ] && find -L ${library}/bin -iname '*.dll' -type f -exec cp {} ${archAttrs.prefix} \;
        '')
      archAttrs.sharedLibraries;
    in
      lib.concatStringsSep "\n" i;
    copyGameAndEditor = archAttrs:
      (
        lib.optionalString (!builtins.isNull archAttrs.doom2df)
        (
          if archAttrs.asLibrary
          then ''
            [ -d "${archAttrs.doom2df}/lib" ] && find -L ${archAttrs.doom2df}/lib -type f -exec cp {} ${archAttrs.prefix} \;
          ''
          else ''
            [ -d "${archAttrs.doom2df}/bin" ] && find -L ${archAttrs.doom2df}/bin -type f -exec cp {} ${archAttrs.prefix} \;
          ''
        )
      )
      + (
        lib.optionalString (!builtins.isNull archAttrs.editor)
        ''
          [ -d "${archAttrs.editor}/bin" ] && find -L ${archAttrs.editor}/bin -type f -exec cp {} ${archAttrs.prefix} \;
        ''
      );
    copyEachArch = arch: archAttrs: ''
      mkdir -p "${archAttrs.prefix}"
      ${copyLibraries archAttrs}
      ${copyGameAndEditor archAttrs}
    '';
  in
    lib.foldlAttrs (acc: n: v: acc + (copyEachArch n v)) "" byArchPkgsAttrs;

  installPhase = ''
    mkdir -p $out
    cp -r * $out
    rm $out/env-vars
  '';
}
