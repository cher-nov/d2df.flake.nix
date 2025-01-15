{
  pkgs,
  lib,
  pins,
  osxcross,
}: let
  toolchain = osxcross.packages.${pkgs.system}.toolchain_13_0;
  sdk = "${toolchain}/SDK/MacOSX13.0.sdk/usr";
  macCmakeDrv = {
    pname,
    version,
    src,
  }: {
    cmakeListsPath ? null,
    cmakePrefix ? "",
    cmakeExtraArgs ? "",
    ...
  }: let
    cmake = "${pkgs.cmake}/bin/cmake";
  in
    pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      inherit version src;
      pname = "${pname}-arm64-apple-darwin21.4";

      dontStrip = true;
      dontPatchELF = true;

      phases = ["unpackPhase" "buildPhase" "installPhase"];

      buildPhase = ''
        runHook preBuild
        ${lib.optionalString (!builtins.isNull cmakeListsPath) "cd ${cmakeListsPath}"}
        mkdir build
        cd build
        export OSXCROSS_SDK="${sdk}"
        export OSXCROSS_HOST="arm64-apple-darwin22.1"
        export OSXCROSS_TARGET="${toolchain}"
        export OSXCROSS_TARGET_DIR="${toolchain}"
        ${cmakePrefix} \
          ${cmake} .. \
            -DCMAKE_TOOLCHAIN_FILE=${osxcross}/tools/toolchain.cmake \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX=$out \
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
  architectures = {
    arm64-apple-darwin = {
      fpcAttrs = let
        name = "arm64-apple-darwin22.1";
      in rec {
        cpuArgs = ["-XP${toolchain}/bin/${name}-"];
        targetArg = "-Tdarwin";
        basename = "crossa64";
        makeArgs = {
          OS_TARGET = "darwin";
          CPU_TARGET = "aarch64";
          CROSSOPT = "\"" + (lib.concatStringsSep " " cpuArgs) + "\"";
        };
        toolchainPaths = [
          "${toolchain}/bin"
        ];
      };
    };
  };
  cross = (import ../_common {inherit pins;}) {cmakeDrv = macCmakeDrv;};
in {
  arm64-apple-darwin = {
    infoAttrs = architectures.arm64-apple-darwin;
    libxmp = cross.libxmp {};
    SDL2 = cross.SDL2 {};
  };
}
