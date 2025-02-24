{
  stdenv,
  executables,
  assets,
  licenses ? null,
  cdrkit,
  macOsIcns,
  macOsPlist,
  lib,
  rcodesign,
  macdylibbundler,
  cctools,
  findutils,
  writeText,
  _7zz,
}: let
  arches = executables.meta.arches;
  perArch = attrs: let
    name = attrs.appBundleName;
  in ''
    cd /build/build
    mkdir -p Doom2DF.app/Contents/lib/${name}
    cp $TMP/${name}/Doom2DF Doom2DF.app/Contents/MacOS/Doom2DF_${name}
    cd $TMP/${name}
    dylibbundler -ns -of -b \
      -s $TMP/${name} \
      -d /build/build/Doom2DF.app/Contents/lib/${name} -p '@executable_path/../lib/${name}' -x /build/build/Doom2DF.app/Contents/MacOS/Doom2DF_${name}
  '';
  # Due to a bug in MacOS, Rosetta (Intel) would always be used on M series MacBooks.
  # Create a shim to launch with preferred architectures.
  # https://stackoverflow.com/questions/68199148/application-reports-different-architecture-depending-on-launch-method
  script = writeText "launcher" (
    ''
      #!/bin/bash
      script_path="$(dirname "$0")"
      ARCHPREFERENCE=arm64,x86_64 arch "$script_path/Doom2DF"
    '');
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "d2df-app-bundle";
    version = "0.667";

    buildInputs = [_7zz cdrkit rcodesign macdylibbundler findutils];

    nativeBuildInputs = lib.flatten (lib.map (x: x.sharedLibraries) (lib.attrValues arches));

    src = null;

    dontUnpack = true;

    buildPhase =
      ''
        cd /build
        mkdir -p build
        cd build
        mkdir -p Doom2DF.app/Contents/{MacOS,Resources}
        cp ${macOsPlist} Doom2DF.app/Contents/Info.plist
      ''
      + (
        ''
          TMP=$(mktemp -d)
          7zz x -mtm -ssp -y ${executables} -o$TMP
        ''
        + lib.concatStringsSep "\n" (lib.map (x: perArch x.value) (lib.attrsToList arches))
        + ''
          cd /build/build
        ''
        + ''
          ${cctools}/bin/x86_64-apple-darwin20.4-lipo ${lib.concatStringsSep " "
            (lib.map (x: "Doom2DF.app/Contents/MacOS/Doom2DF_${x.value.appBundleName}") (lib.attrsToList arches))} -create -output Doom2DF.app/Contents/MacOS/Doom2DF
          find Doom2DF.app/Contents/MacOS/ -iname 'Doom2DF_*' -exec rm {} \;
        ''
      )
      + (''
          cp ${macOsIcns} Doom2DF.app/Contents/Resources/Doom2DF.icns
          7zz x -mtm -ssp -y ${assets} -oDoom2DF.app/Contents/Resources
        ''
        + lib.optionalString (!builtins.isNull licenses) ''
          7zz x -mtm -ssp -y ${licenses} -oDoom2DF.app/Contents/Resources
        '')
      + ''
        cd /build
        rcodesign -v sign build/Doom2DF.app
        cp ${script} build/Doom2DF.app/Contents/MacOS/Doom2DF_Launcher
        chmod -R 777 build/Doom2DF.app
        genisoimage -D -V "Doom2D Forever" -no-pad -r -apple -file-mode 0555 \
          -o out.dmg build
      '';

    installPhase = ''
      cd /build
      mv out.dmg $out
    '';
  })
