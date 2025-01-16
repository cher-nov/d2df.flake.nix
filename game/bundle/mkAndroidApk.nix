args @ {
  stdenv,
  jdk17,
  jdk8,
  findutils,
  coreutils-full,
  file,
  androidSdk,
  lib,
  SDL2ForJava,
  androidRoot,
  mkAndroidManifest,
  androidIcons,
  gameAssetsPath,
  gameExecutablePath,
}:
stdenv.mkDerivation (finalAttrs: let
  ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
  ANDROID_JAR = "${ANDROID_HOME}/platforms/android-34/android.jar";
  aapt = "${ANDROID_HOME}/build-tools/28.0.3/aapt";
  jdk = jdk17;
  jdkSign = jdk8;
  d8 = "${ANDROID_HOME}/build-tools/35.0.0/d8";
  androidManifest = mkAndroidManifest {
    packageName = "org.d2df.app";
    versionName = "0.667-git";
    minSdkVersion = "21";
    targetSdkVersion = "29";
    glEsVersion = "0x00010001";
  };
in {
  version = "0.667-git";
  pname = "d2df-apk";
  name = "${finalAttrs.pname}-${finalAttrs.version}";

  nativeBuildInputs = [findutils jdk coreutils-full file];

  src = androidRoot;

  buildPhase =
    # Precreate directories to be used in the build process.
    ''
      mkdir -p bin obj gen res
      mkdir -p resources aux/lib
    ''
    + ''
      cp -r ${androidIcons}/* res
      cp -r ${gameAssetsPath}/* resources/
      cp -r ${gameExecutablePath}/* aux/lib/
      cp ${androidManifest} AndroidManifest.xml
    ''
    # Use SDL Java sources from the version we compiled our game with.
    + ''
      cp -r "${SDL2ForJava.src}/android-project/app/src/main/java/org/libsdl/app" "src/org/libsdl"
    ''
    # Build the APK.
    + ''
      ${aapt} package -f -m -S res -J gen -M AndroidManifest.xml -I ${ANDROID_JAR}
      ${jdkSign}/bin/javac -encoding UTF-8 -source 1.8 -target 1.8 -classpath "${ANDROID_JAR}" -d obj gen/org/d2df/app/R.java $(find src -name '*.java')
      ${d8} $(find obj -name '*.class') --lib ${ANDROID_JAR} --output bin/classes.jar
      ${d8} ${ANDROID_JAR} bin/classes.jar --output bin
      ${aapt} package -f -M ./AndroidManifest.xml -S res -I ${ANDROID_JAR} -F bin/d2df.unsigned.apk -A resources bin aux
      ${jdkSign}/bin/keytool -genkey -validity 10000 -dname "CN=AndroidDebug, O=Android, C=US" -keystore d2df.keystore -storepass android -keypass android -alias androiddebugkey -sigalg MD5withRSA -keyalg RSA -keysize 1024 -v
      ${jdkSign}/bin/jarsigner -sigalg MD5withRSA -digestalg SHA1 -keystore d2df.keystore -storepass android -keypass android -signedjar bin/d2df.signed.apk bin/d2df.unsigned.apk androiddebugkey
    '';

  installPhase = ''
    cp bin/d2df.signed.apk $out
  '';
})
