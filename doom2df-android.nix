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
  jdk8,
  fetchFromGitHub,
  findutils,
  # The derivations below are from this repo
  fpc-android,
  androidSdk,
}: let
  ANDROID_JAR = "$ANDROID_HOME/platforms/android-28/android.jar";
  ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
  ANDROID_NDK = "${androidSdk}/libexec/android-sdk/ndk-bundle";
  ANDROID_JAVA_HOME = "${jdk8.home}";
  NDK_TOOLCHAIN = "${ANDROID_NDK}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin";
  NDK_LIB = "${ANDROID_NDK}/platforms/android-28/arch-arm64/usr/lib";
  aapt = "${androidSdk}/build-tools/28.0.3/aapt";
  dx = "${androidSdk}/build-tools/28.0.3/dx";
  jdk = jdk8;

  SDL2_custom = stdenv.mkDerivation (finalAttrs: {
    pname = "SDL2";
    version = "2.30.6";

    src = fetchFromGitHub {
      owner = "libsdl-org";
      repo = "SDL";
      rev = "release-${finalAttrs.version}";
      hash = "sha256-ij9/VhSacUaPbMGX1hx2nz0n8b1tDb1PnC7IO9TlNhE=";
    };

    patches = [
      ./0001-Temporary-changes-to-accomodate-my-work-on-nixifying.patch
    ];

    buildPhase = ''
      runHook preBuild
      mkdir build
      cd build
      cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
        -DBUILD_SHARED_LIBS=ON -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-28
      make -j$(nproc)
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp libSDL2.so $out/lib
      runHook postInstall
    '';
  });
in
  stdenv.mkDerivation (finalAttrs: {
    version = "0.667-git";
    pname = "d2df-android";
    name = "${finalAttrs.pname}-${finalAttrs.version}";

    src = fetchgit {
      url = "https://repo.or.cz/d2df-sdl.git";
      rev = "5ed07397455b97d2312b2255612c6563aff98190";
      sha256 = "sha256-QbE2BSfpEU4fAFIL7jGjFN+kgnlo54rBOMzEWLG3DRs=";
    };

    buildPhase = ''
      runHook preBuild
      cd src/game
      mkdir bin tmp
      export PATH='${NDK_TOOLCHAIN}:$PATH'
      ${fpc-android}/bin/ppcrossa64 -g -gl -O1 \
        -Tandroid -CpARMV8 -CfVFP \
        -FEbin -FUtmp \
        -dUSE_SDL2 -dUSE_SOUNDSTUB -dUSE_GLES1 \
        -Fl${SDL2_custom}/lib \
        -olibDoom2DF.so \
        Doom2DF.lpr

      cd ../../android
      keytool -genkey -validity 10000 -dname "CN=AndroidDebug, O=Android, C=US" \
        -keystore d2df.keystore -storepass android -keypass android \
        -alias androiddebugkey -keyalg RSA -keysize 2048 -v
      rm -rf bin obj gen
      mkdir -p bin obj gen resources
      ${aapt} package -f -m -S res -J gen -M AndroidManifest.xml -I ${ANDROID_JAR}
      ${jdk}/bin/javac -source 1.6 -target 1.6 -d obj -bootclasspath ${ANDROID_JAR} \
        -sourcepath src $(${findutils}/bin/find src -name '*.java')
      ${dx} --dex --output=bin/classes.dex obj
      ${aapt} package -f    -S res -J gen -M AndroidManifest.xml -I ${ANDROID_JAR} \
        -F bin/d2df.unsigned.apk -A resources \
        bin ass
      ${jdk}/bin/jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore d2df.keystore \
        -storepass android -keypass android \
        -signedjar bin/d2df.signed.apk bin/d2df.unsigned.apk androiddebugkey
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp bin/d2df.signed.apk $out/bin
      runHook postInstall
    '';
  })
