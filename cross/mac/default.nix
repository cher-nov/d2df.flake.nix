{
  pkgs,
  lib,
  pins,
  osxcross,
}: let
  toolchain = osxcross.packages.${pkgs.system}.toolchain_15_2;
  sdk = "${toolchain}/SDK/MacOSX15.2.sdk";
  target = "apple-darwin22.1";
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
      pname = "${pname}-aarch64-${target}";

      dontStrip = true;
      dontPatchELF = true;

      phases = ["unpackPhase" "buildPhase" "installPhase"];

      # https://github.com/tpoechtrager/osxcross/issues/345
      # https://github.com/sbmpost/AutoRaise/issues/69
      buildPhase = let
        CFLAGS = lib.concatStringsSep " " [
          "-target aarch64-apple-darwin22.1"
          "-I${pkgs.llvmPackages.clang-unwrapped.lib}/lib/clang/18/include"
          #"-L${sdk}/usr/lib/system"
          "-I${sdk}/usr/include"
          "-isystem ${sdk}/usr/include"
          "-iframework ${sdk}/System/Library/Frameworks"
          /*
          "-framework Foundation"
          "-framework AudioUnit"
          "-framework Cocoa"
          "-framework CoreAudio"
          "-framework CoreServices"
          "-framework ForceFeedback"
          "-framework OpenGL"
          */
        ];
        LDFLAGS = lib.concatStringsSep " " [
          "-target aarch64-apple-darwin22.1"
          "-I${pkgs.llvmPackages.clang-unwrapped.lib}/lib/clang/18/include"
          "-I${sdk}/usr/include"
          "-isystem ${sdk}/usr/include"
          "-iframework ${sdk}/System/Library/Frameworks"
        ];
      in ''
        runHook preBuild
        ${lib.optionalString (!builtins.isNull cmakeListsPath) "cd ${cmakeListsPath}"}
        mkdir build
        cd build
        export OSXCROSS_SDK="${sdk}"
        export OSXCROSS_HOST="aarch64-${target}"
        export OSXCROSS_TARGET="${toolchain}"
        export OSXCROSS_TARGET_DIR="${toolchain}"
        export OSXCROSS_CLANG_INTRINSIC_PATH="${pkgs.llvmPackages.clang-unwrapped.lib}/lib/clang/"
        export CFLAGS="$CFLAGS ${CFLAGS}"
        export LDFLAGS="$LDFLAGS ${LDFLAGS}"
        ${cmakePrefix} \
          ${cmake} .. \
            -DCMAKE_TOOLCHAIN_FILE=${osxcross}/tools/toolchain.cmake \
            -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=OFF \
            -DCMAKE_INSTALL_PREFIX=$out \
            ${cmakeExtraArgs}
        make -j12 VERBOSE=1
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
        name = "aarch64-apple-darwin22.1";
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
