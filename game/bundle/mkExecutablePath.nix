{
  # Example:
  # {"arm64-v8a" = { isWindows = false; sharedLibraries = [SDL2_custom enet_custom]; doom2df = .../null; editor = .../null; asLibrary = false; prefix = "arm64-v8a"}; }
  byArchPkgsAttrs,
  stdenvNoCC,
  withDates ? false,
  gameDate ? null,
  editorDate ? null,
  gnused,
  gawk,
  zip,
  findutils,
  outils,
  _7zz,
  lib,
  coreutils,
}:
stdenvNoCC.mkDerivation {
  pname = "d2df-executable-path";
  version = "git";
  phases = ["buildPhase" "installPhase"];

  src = null;

  dontPatchELF = true;
  dontStrip = true;
  dontFixup = true;

  nativeBuildInputs = [gawk gnused zip findutils outils coreutils _7zz];

  buildPhase = let
    copyLibraries = archAttrs: let
      i = lib.map (library:
        ''
          [ -d "${library}/lib" ] && find -L ${library}/lib -iname '*.so' -type f -exec cp {} ${archAttrs.prefix} \;
        ''
        + ''
          [ -d "${library}/lib" ] && find -L ${library}/lib -iname '*.dylib' -type f -exec cp {} ${archAttrs.prefix} \;
        ''
        + lib.optionalString archAttrs.isWindows ''
          [ -d "${library}/bin" ] && find -L ${library}/bin -iname '*.dll' -type f -exec cp {} ${archAttrs.prefix} \;
        ''
        + lib.optionalString withDates ''
          find -L ${archAttrs.prefix} -iname '*.so' -or -iname '*.dylib' -or -iname '*.dll' -exec touch -d "${gameDate}" \;
        '')
      archAttrs.sharedLibraries;
    in
      lib.concatStringsSep "\n" (i
        ++ [
          "mv ${archAttrs.prefix}/libogg.dll ${archAttrs.prefix}/ogg.dll || :"
          "find -L ${archAttrs.prefix} -iname 'libsyn123*' -type f -exec rm {} +"
          "find -L ${archAttrs.prefix} -iname 'libvorbisenc*' -type f -exec rm {} +"
        ]);
    copyGameAndEditor = archAttrs: let
      suffix = lib.optionalString (archAttrs.isWindows) ".exe";
    in let
      script = suffix: ''        \
                         TARGET=${archAttrs.prefix}/''${0##*/}${suffix}; \
                         cp $0 $TARGET; \
                         ${lib.optionalString withDates "touch -d \"${gameDate}\" $TARGET"}'';
    in (
      lib.optionalString (!builtins.isNull archAttrs.doom2df)
      (
        if archAttrs.asLibrary
        then ''
          [ -d "${archAttrs.doom2df}/lib" ] && find -L ${archAttrs.doom2df}/lib -type f \
             -exec sh -c '${script ""}' {} \;
        ''
        else ''
          [ -d "${archAttrs.doom2df}/bin" ] && find -L ${archAttrs.doom2df}/bin -type f \
             -exec sh -c '${script suffix}' {} \;
        ''
      )
      + (
        lib.optionalString (!builtins.isNull archAttrs.editor)
        ''
          [ -d "${archAttrs.editor}/bin" ] && find -L ${archAttrs.editor}/bin -type f \
             -exec sh -c '${script suffix}' {} \;
        ''
      )
    );
    copyEachArch = arch: archAttrs: ''
      mkdir -p "${archAttrs.prefix}"
      ${copyLibraries archAttrs}
      ${copyGameAndEditor archAttrs}
    '';
  in ''
    mkdir -p build
    cd build
    ${lib.concatStringsSep "\n" (lib.map (x: copyEachArch x.name x.value) (lib.attrsToList byArchPkgsAttrs))}
  '';

  installPhase = ''
    cd /build
    7zz a -y -mtm -ssp -tzip out.zip -w build/.
    mv out.zip $out
  '';

  meta = {
    licenses = let
      getLibraries = arch: arch.sharedLibraries ++ [arch.doom2df];
      all = lib.foldl (acc: cur: acc ++ (getLibraries cur)) [] (lib.attrValues byArchPkgsAttrs);
      files =
        lib.map (x: {
          inherit (x) pname;
          license = x.meta.licenseFiles;
        })
        all;
    in
      files;
  };
}
