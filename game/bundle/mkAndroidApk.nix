{
  stdenv,
  jdk17,
  findutils,
  coreutils-full,
  file,
  androidSdk,
  lib,
  SDL2ForJava,
  androidRoot,
  androidRes,
  gameAssetsPath,
  # Example:
  # {"arm64-v8a" = { nativeBuildInputs = [SDL2_custom enet_custom]; doom2df = ...}; }
  customAndroidFpcPkgs,
}:
stdenv.mkDerivation (finalAttrs: let
  ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
  ANDROID_JAR = "${ANDROID_HOME}/platforms/android-34/android.jar";
  aapt = "${ANDROID_HOME}/build-tools/28.0.3/aapt";
  d8 = "${ANDROID_HOME}/build-tools/35.0.0/d8";
  jdk = jdk17;
in {
  version = "0.667-git";
  pname = "d2df-apk";
  name = "${finalAttrs.pname}-${finalAttrs.version}";

  nativeBuildInputs = [findutils jdk coreutils-full file];

  src = androidRoot;

  buildPhase =
    # Precreate directories to be used in the build process.
    ''
      mkdir -p bin obj gen
      mkdir -p resources ass/lib
      ln -s ${androidRes}/ res
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
        cp -r ${gameAssetsPath}/* resources
      '')
    # Use SDL Java sources from the version we compiled our game with.
    + ''
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
    cp bin/d2df.signed.apk $out
  '';
})
