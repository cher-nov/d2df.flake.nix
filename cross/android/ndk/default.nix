{
  lib,
  pkgs,
  fetchFromGitHub,
  stdenv,
  pins,
}: let
  common = import ../../_common {inherit pins;};
  androidCmakeDrv = {
    pname,
    version,
    src,
  }: {
    androidSdk,
    androidNdk,
    androidAbi,
    androidPlatform,
    cmakeListsPath ? null,
    cmakePrefix ? "",
    cmakeExtraArgs ? "",
    ...
  }: let
    cmake = "${pkgs.cmake}/bin/cmake";
  in
    pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      inherit version src;
      pname = "${pname}-${androidAbi}";

      dontStrip = true;
      dontPatchELF = true;

      phases = ["unpackPhase" "buildPhase" "installPhase"];

      buildPhase = ''
        runHook preBuild
        ${lib.optionalString (!builtins.isNull cmakeListsPath) "cd ${cmakeListsPath}"}
        mkdir build
        cd build
        ${cmakePrefix} \
          ${cmake} .. \
            -DCMAKE_TOOLCHAIN_FILE=${androidNdk}/build/cmake/android.toolchain.cmake \
            -DCMAKE_POLICY_DEFAULT_CMP0057=NEW \
            -DBUILD_SHARED_LIBS=ON -DANDROID_ABI=${androidAbi} -DANDROID_PLATFORM=${androidPlatform} \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX=$out -DANDROID_STL=c++_static \
            ${cmakeExtraArgs}
        make -j$(nproc)
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib
        make install
        runHook postInstall
      '';
    });
in
  common {cmakeDrv = androidCmakeDrv;}
