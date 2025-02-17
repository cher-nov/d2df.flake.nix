let
  gameBundle = {
    stdenv,
    gameAssetsPath,
    gameExecutablePath,
    git,
    lib,
  }:
    stdenv.mkDerivation (finalAttrs: {
      version = "0.667-git";
      pname = "d2df-game-path";
      name = "${finalAttrs.pname}-${finalAttrs.version}";

      buildInputs = [git];

      dontStrip = true;
      dontPatchELF = true;
      dontFixup = true;
      dontBuild = true;
      dontUnpack = true;

      src = null;

      installPhase = ''
        mkdir -p $out/assets $out/executables $out/legal
        cp -r ${gameAssetsPath}/* $out/assets
        cp -r ${gameExecutablePath}/* $out/executables
        ${let
          licenses = lib.flatten gameExecutablePath.meta.licenses;
          transformName = licenseFile: pname: let
            basename = builtins.baseNameOf licenseFile;
            split = lib.splitString "." basename;
          in
            if (lib.length split) == 1
            then "${basename}.${pname}.txt"
            else "${lib.concatStringsSep "." (lib.lists.init split)}.${pname}.${lib.strings.toLower (lib.lists.last split)}";
          perLicenseAttrs = licenseAttrs: lib.map (x: "cp ${x} $out/legal/${transformName x licenseAttrs.pname}") licenseAttrs.license;
          final = lib.map perLicenseAttrs licenses;
        in
          lib.concatStringsSep " ;\n" (lib.flatten final)}
      '';
    });
in
  gameBundle
