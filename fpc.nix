{
  lib,
  stdenv,
  fetchurl,
  fetchgit,
  gawk,
  fetchpatch,
  undmg,
  cpio,
  xar,
  darwin,
  libiconv,
  fpc,
  androidSdk
}: let
  startFPC = fpc;
in
  stdenv.mkDerivation rec {
    version = "3.2.2";
    pname = "fpc-android";
      src = fetchgit {
        url = "https://gitlab.com/freepascal.org/fpc/source.git";
        rev = "46508f6af16b7f676ca05bc9f84f904d3c2aac23";
        sha256 = "sha256-0HjI4FXWXA8P468dK7GLSofgDdPfCSvyohJlIbS/KSc=";
      };

    buildInputs = [stdenv gawk fpc]; 
    glibc = stdenv.cc.libc.out;

    patches = [./0001-Mark-paths-for-NixOS.patch];

      postPatch = ''
        # substitute the markers set by the mark-paths patch
        substituteInPlace compiler/systems/t_linux.pas --subst-var-by dynlinker-prefix "${glibc}"
        substituteInPlace compiler/systems/t_linux.pas --subst-var-by syslibpath "${glibc}/lib"
        # Replace the `codesign --remove-signature` command with a custom script, since `codesign` is not available
        # in nixpkgs
        # Remove the -no_uuid strip flag which does not work on llvm-strip, only
        # Apple strip.
        substituteInPlace compiler/Makefile \
          --replace \
            "\$(CODESIGN) --remove-signature" \
            "${fpc}/remove-signature.sh}" \
          --replace "ifneq (\$(CODESIGN),)" "ifeq (\$(OS_TARGET), darwin)" \
          --replace "-no_uuid" ""
      '';

    buildPhase = ''
      export ANDROID_NDK_HOME="${androidSdk}/libexec/android-sdk/ndk-bundle";
      export PATH="$ANDROID_NDK_HOME:$PATH"; 
      export PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH";
      make crossall OS_TARGET=android CPU_TARGET=arm FPC="${fpc}/bin/fpc" PP="${fpc}/bin/fpc" INSTALL_PREFIX=$out
    ''; 

    installPhase = ''
      make install INSTALL_PREFIX=$out
    '';

    meta = with lib; {
      description = "Free Pascal Compiler from a source distribution";
      homepage = "https://www.freepascal.org";
      maintainers = [maintainers.raskin];
      license = with licenses; [gpl2 lgpl2];
      platforms = platforms.unix;
    };
  }
