# Grep for V/SDL
/*
10-20 17:23:17.579 V/SDL     (23013): Running main function SDL_main from library libDoom2DF.so
10-20 17:23:17.580 V/SDL     (23013): nativeRunMain()
10-20 17:23:17.580 E/SDL     (23013): nativeRunMain(): Couldn't load library libDoom2DF.so
10-20 17:23:17.580 V/SDL     (23013): Finished main function
*/
{
  stdenv,
  fetchFromGitHub,
}: let
  androidCmakeDrv = {
    pname,
    version,
    src,
    cmakeExtraArgs ? "",
  }: {
    androidSdk,
    androidNdk,
    androidAbi,
    androidPlatform,
  }: let
    cmake = "${androidSdk}/libexec/android-sdk/cmake/3.22.1/bin/cmake";
  in
    stdenv.mkDerivation (finalAttrs: {
      inherit pname version src;

      buildPhase = ''
        runHook preBuild
        mkdir build
        cd build
        export PATH="$ANDROID_SDK_ROOT/cmake/*/bin:$PATH";
        ${cmake} .. \
          -DCMAKE_TOOLCHAIN_FILE=${androidNdk}/build/cmake/android.toolchain.cmake \
          -DBUILD_SHARED_LIBS=ON -DANDROID_ABI=${androidAbi} -DANDROID_PLATFORM=${androidPlatform} \
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

  SDL2_custom = androidCmakeDrv rec {
    pname = "SDL2";
    version = "2.30.6";
    src = fetchFromGitHub {
      owner = "libsdl-org";
      repo = "SDL";
      rev = "release-${version}";
      hash = "sha256-ij9/VhSacUaPbMGX1hx2nz0n8b1tDb1PnC7IO9TlNhE=";
    };
  };

  enet_custom = androidCmakeDrv {
    pname = "enet";
    version = "1.3.18";
    src = fetchFromGitHub {
      owner = "lsalzman";
      repo = "enet";
      rev = "1e80a78f481cb2d2e4d9a0e2718b91995f2de51c";
      hash = "sha256-YIqJC5wMTX4QiWebvGGm5EfZXLzufXBxUO7YdeQ+6Bk=";
    };
  };

  doom2dfAndroidNativeLibrary = {
    stdenv,
    fetchgit,
    fpc,
    ndkToolchain,
    SDL2_custom,
    enet_custom,
  }:
    stdenv.mkDerivation (finalAttrs: {
      version = "0.667-git";
      pname = "d2df-android-lib";
      name = "${finalAttrs.pname}-${finalAttrs.version}";

      src = fetchgit {
        url = "https://repo.or.cz/d2df-sdl.git";
        rev = "58bea163d93100936cfe20515526e76f6cdf8ddb";
        sha256 = "sha256-oCxv3VjAqxB887Rwe6JLELjHo4b9ISjvdpme6Zs12j4=";
      };

      patches = [./0001-Experimental-network-patch.patch];

      buildPhase = ''
        pushd src/game
        mkdir bin tmp
        PATH='${ndkToolchain}:$PATH' \
          ${fpc}/bin/fpc \
            -g -gl -O1 \
            -FEbin -FUtmp \
            -dUSE_SDL2 -dUSE_SOUNDSTUB -dUSE_GLES1 \
            -Fl${SDL2_custom}/lib -Fl${enet_custom}/lib \
            -olibDoom2DF.so \
            -al Doom2DF.lpr
        popd
      '';

      installPhase = ''
        mkdir -p $out/lib
        cp src/game/bin/libDoom2DF.so $out/lib
      '';
    });
in {
  inherit SDL2_custom enet_custom;
  inherit doom2dfAndroidNativeLibrary;
  doom2df-android = {
    stdenv,
    jdk17,
    findutils,
    coreutils-full,
    file,
    androidSdk,
    lib,
    SDL2ForJava,
    # Example:
    # {"arm64-v8a" = { nativeBuildInputs = [SDL2_custom enet_custom]; doom2df = ...}; }
    customAndroidFpcPkgs,
  }:
    stdenv.mkDerivation (finalAttrs: let
      ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
      ANDROID_JAR = "${ANDROID_HOME}/platforms/android-34/android.jar";
      aapt = "${ANDROID_HOME}/build-tools/28.0.3/aapt";
      d8 = "${ANDROID_HOME}/build-tools/34.0.0/d8";
      jdk = jdk17;
    in {
      version = "0.667-git";
      pname = "d2df-apk";
      name = "${finalAttrs.pname}-${finalAttrs.version}";

      nativeBuildInputs = [findutils jdk coreutils-full file];

      src = ./android;

      buildPhase =
        # Precreate directories to be used in the build process.
        ''
          mkdir -p bin obj gen
          mkdir -p resources ass/lib
        ''
        # Populate native library directories for supported platforms.
        + (let
          copyLibraries = abi: libraries: let
            i = lib.map (x: "ln -s ${x}/lib/*.so ass/lib/${abi}") libraries;
          in
            lib.concatStringsSep "\n" i;
          f = abi: abiAttrs: ''
            mkdir -p "ass/lib/${abi}"
            ${(copyLibraries abi abiAttrs.nativeBuildInputs)}
            ln -s "${abiAttrs.doom2df}/lib/libDoom2DF.so" ass/lib/${abi}/libDoom2DF.so
          '';
        in
          (lib.foldlAttrs (acc: name: value: acc + (f name value)) "" customAndroidFpcPkgs)
          + ''
            cp -r assets/* resources
          '')
        # Use SDL Java sources from the version we compiled our game with.
        + ''
          rm -r src/org/libsdl/app/*
          cp -r "${SDL2ForJava.src}/android-project/app/src/main/java/org/libsdl/app" "src/org/libsdl"
        ''
        # Build the APK.
        + ''
          ${aapt} package -f -m -S res -J gen -M AndroidManifest.xml -I ${ANDROID_JAR}
          ${jdk}/bin/javac -encoding UTF-8 -source 1.8 -target 1.8 -classpath "${ANDROID_JAR}" -d obj gen/org/d2df/app/R.java $(find src -name '*.java')
          ${d8} $(find obj -name '*.class') --lib ${ANDROID_JAR} --output bin/classes.jar
          ${d8} ${ANDROID_JAR} bin/classes.jar --output bin
          ${aapt} package -f -M ./AndroidManifest.xml -S res -I ${ANDROID_JAR} -F bin/d2df.unsigned.apk -A resources bin ass
          ${jdk}/bin/keytool -genkey -validity 10000 -dname "CN=AndroidDebug, O=Android, C=US" -keystore d2df.keystore -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -v
          ${jdk}/bin/jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore d2df.keystore -storepass android -keypass android -signedjar bin/d2df.signed.apk bin/d2df.unsigned.apk androiddebugkey
        '';

      installPhase = ''
        mkdir -p $out/bin
        cp bin/d2df.signed.apk $out/bin
      '';
    });
}
