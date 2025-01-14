{
  stdenvNoCC,
  packageName,
  versionName,
  minSdkVersion,
  targetSdkVersion,
  glEsVersion,
}: let
  srcManifest = ./android/AndroidManifest.xml;
in
  stdenvNoCC.mkDerivation {
    pname = "d2df-android-manifest";
    version = versionName;

    src = srcManifest;
    dontUnpack = true;

    buildPhase = ''
      cp $src AndroidManifest.xml
      substituteInPlace AndroidManifest.xml --subst-var-by androidPackageName ${packageName}
      substituteInPlace AndroidManifest.xml --subst-var-by androidVersionName ${versionName}
      substituteInPlace AndroidManifest.xml --subst-var-by androidMinSdkVersion ${minSdkVersion}
      substituteInPlace AndroidManifest.xml --subst-var-by androidTargetSdkVersion ${targetSdkVersion}
      substituteInPlace AndroidManifest.xml --subst-var-by androidGlEsVersion ${glEsVersion}
    '';

    installPhase = ''
      cp AndroidManifest.xml $out
    '';
  }
