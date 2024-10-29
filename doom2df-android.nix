# Grep for V/SDL
/*
10-20 17:23:17.579 V/SDL     (23013): Running main function SDL_main from library libDoom2DF.so
10-20 17:23:17.580 V/SDL     (23013): nativeRunMain()
10-20 17:23:17.580 E/SDL     (23013): nativeRunMain(): Couldn't load library libDoom2DF.so
10-20 17:23:17.580 V/SDL     (23013): Finished main function
*/
{
  stdenv,
  fetchgit,
  lib,
  jdk17,
  fetchFromGitHub,
  findutils,
  # The derivations below are from this repo
  fpc-android,
  androidSdk,
  pkgs,
}: let
  androidPlatform = 28;

  ANDROID_ABI = "arm64-v8a";
  ANDROID_PLATFORM = "android-${builtins.toString androidPlatform}";
  ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
  ANDROID_JAR = "${ANDROID_HOME}/platforms/android-34/android.jar";
  ANDROID_NDK = "${androidSdk}/libexec/android-sdk/ndk-bundle";
  NDK_TOOLCHAIN = "${ANDROID_NDK}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin";
  NDK_LIB = "${ANDROID_NDK}/platforms/android-28/arch-arm64/usr/lib";
  aapt = "${ANDROID_HOME}/build-tools/28.0.3/aapt";
  d8 = "${ANDROID_HOME}/build-tools/34.0.0/d8";
  cmake = "${ANDROID_HOME}/cmake/3.22.1/bin/cmake";
  jdk = jdk17;
  jarsigner = "${pkgs.jdk}/bin/jarsigner";
  ANDROID_JAVA_HOME = "${jdk.home}";

  SDL2_custom = let
    inherit ANDROID_PLATFORM ANDROID_ABI;
    baseName = "SDL2";
  in
    stdenv.mkDerivation (finalAttrs: {
      pname = "SDL2";
      version = "2.30.6";

      src = fetchFromGitHub {
        owner = "libsdl-org";
        repo = "SDL";
        rev = "release-${finalAttrs.version}";
        hash = "sha256-ij9/VhSacUaPbMGX1hx2nz0n8b1tDb1PnC7IO9TlNhE=";
      };

      buildPhase = ''
        runHook preBuild
        mkdir build
        cd build
        export PATH="$ANDROID_SDK_ROOT/cmake/*/bin:$PATH";
        ${cmake} .. \
          -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
          -DBUILD_SHARED_LIBS=ON -DANDROID_ABI=${ANDROID_ABI} -DANDROID_PLATFORM=${ANDROID_PLATFORM}
        make -j$(nproc)
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib
        cp lib${baseName}.so $out/lib
        runHook postInstall
      '';
    });

  enet_custom = let
    inherit ANDROID_PLATFORM ANDROID_ABI;
    baseName = "enet";
  in
    stdenv.mkDerivation (finalAttrs: {
      pname = "enet";
      version = "1.3.18";

      src = fetchFromGitHub {
        owner = "lsalzman";
        repo = "enet";
        rev = "1e80a78f481cb2d2e4d9a0e2718b91995f2de51c";
        hash = "sha256-YIqJC5wMTX4QiWebvGGm5EfZXLzufXBxUO7YdeQ+6Bk=";
      };

      buildPhase = ''
        runHook preBuild
        mkdir build
        cd build
        ${cmake} .. \
          -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
          -DBUILD_SHARED_LIBS=ON -DANDROID_ABI=${ANDROID_ABI} -DANDROID_PLATFORM=${ANDROID_PLATFORM}
        make -j$(nproc)
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib
        cp lib${baseName}.so $out/lib
        runHook postInstall
      '';
    });

  doom2dfAndroid = let
    inherit ANDROID_PLATFORM ANDROID_ABI;
    processor = "ARMV8";
    fp = "VFP";
    target = "android";
  in
    stdenv.mkDerivation (finalAttrs: {
      version = "0.667-git";
      pname = "d2df-android-lib";
      name = "${finalAttrs.pname}-${finalAttrs.version}";

      src = fetchgit {
        url = "https://repo.or.cz/d2df-sdl.git";
        rev = "82c4fc8846a8a10c9b493fe2f827fa9d5d511bff";
        sha256 = "sha256-RCp+fPMMNVdxFx9oNhlQ2ou3hMweEzWbVauVtu3n1As=";
      };

      patches = [
        ./0001-Remove-noreturns-from-functions-that-throw.patch
      ];

      buildPhase = ''
        pushd src/game
        mkdir bin tmp
        PATH='${NDK_TOOLCHAIN}:$PATH' \
          ${fpc-android}/bin/ppcrossa64 -g -gl -O1 \
            -T${target} -Cp${processor} -Cf${fp} \
            -FEbin -FUtmp \
            -dUSE_SDL2 -dUSE_SOUNDSTUB -dUSE_GLES1 \
            -Fl${NDK_LIB} \
            -Fl${SDL2_custom}/lib -Fl${enet_custom}/lib \
            -olibDoom2DF.so \
            Doom2DF.lpr
        popd
      '';

      installPhase = ''
        mkdir -p $out/lib
        cp src/game/bin/libDoom2DF.so $out/lib
      '';
    });
in let
  inherit aapt d8 jdk ANDROID_JAR;
in
  stdenv.mkDerivation (finalAttrs: {
    version = "0.667-git";
    pname = "d2df-apk";
    name = "${finalAttrs.pname}-${finalAttrs.version}";

    nativeBuildInputs = [pkgs.findutils jdk pkgs.coreutils-full pkgs.file];

    src = ./android;

    buildPhase = ''
      mkdir -p bin obj gen
      mkdir -p resources ass/lib

      mkdir -p ass/lib/arm64-v8a
      ln -s "${SDL2_custom}/lib/libSDL2.so" ass/lib/arm64-v8a/libSDL2.so
      ln -s "${enet_custom}/lib/libenet.so" ass/lib/arm64-v8a/libenet.so
      ln -s "${doom2dfAndroid}/lib/libDoom2DF.so" ass/lib/arm64-v8a/libDoom2DF.so
      cp assets/* resources -r

      ${aapt} package -f -m -S res -J gen -M AndroidManifest.xml -I ${ANDROID_JAR}
      ${jdk}/bin/javac -encoding UTF-8 -source 1.8 -target 1.8 -classpath "${ANDROID_JAR}" -d obj gen/org/d2df/app/R.java $(find src -name '*.java')
      ${d8} $(find obj -name '*.class') --lib ${ANDROID_JAR} --output bin/classes.jar
      cd bin
      ${d8} ${ANDROID_JAR} classes.jar
      cd ..
      ${aapt} package -f -M ./AndroidManifest.xml -S res -I ${ANDROID_JAR} -F bin/d2df.unsigned.apk -A resources bin ass
      ${jdk}/bin/keytool -genkey -validity 10000 -dname "CN=AndroidDebug, O=Android, C=US" -keystore d2df.keystore -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -v
      ${jdk}/bin/jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore d2df.keystore -storepass android -keypass android -signedjar bin/d2df.signed.apk bin/d2df.unsigned.apk androiddebugkey
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp bin/d2df.signed.apk $out/bin
    '';
  })
