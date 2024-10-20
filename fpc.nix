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
  androidSdk,
}: let
  startFPC = fpc;
in
  stdenv.mkDerivation rec {
    version = "3.3.1";
    pname = "fpc-android";
    src = fetchgit {
      url = "https://gitlab.com/freepascal.org/fpc/source.git";
      rev = "46508f6af16b7f676ca05bc9f84f904d3c2aac23";
      sha256 = "sha256-0HjI4FXWXA8P468dK7GLSofgDdPfCSvyohJlIbS/KSc=";
    };

    buildInputs = [gawk fpc];
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

    #make all NOGDB=1 FPC="${fpc}/bin/fpc" INSTALL_PREFIX=$out
    buildPhase = let
      androidNdk = "${androidSdk}/libexec/android-sdk/ndk-bundle";
      ndkToolchain = "${androidNdk}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin";
      ndkLib = "${androidNdk}/platforms/android-16/arch-arm/usr/lib";
    in ''
      export PATH="$PATH:${ndkToolchain}";
      #export PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH";
      make clean all CROSSOPT="-Fl${ndkLib}" NDK=${androidNdk} NOGDB=1 OS_TARGET=android CPU_TARGET=arm FPC="${fpc}/bin/fpc" PP="${fpc}/bin/fpc" INSTALL_PREFIX=$out
    '';

    installPhase =
      ''
        #make install NOGDB=1 INSTALL_PREFIX=$out
        make crossinstall NOGDB=1 OS_TARGET=android CPU_TARGET=arm INSTALL_PREFIX=$out
      ''
      + ''
        for i in $out/lib/fpc/*/ppc*; do
          ln -fs $i $out/bin/$(basename $i)
        done
      '';

    #mkdir -p $out/lib/fpc/etc/
    #$out/lib/fpc/*/samplecfg $out/lib/fpc/${version} $out/lib/fpc/etc/

    # Generate config files in /etc since on darwin, ppc* does not follow symlinks
    # to resolve the location of /etc
    #mkdir -p $out/etc
    #$out/lib/fpc/*/samplecfg $out/lib/fpc/${version} $out/etc

    meta = with lib; {
      description = "Free Pascal Compiler from a source distribution";
      homepage = "https://www.freepascal.org";
      maintainers = [maintainers.raskin];
      license = with licenses; [gpl2 lgpl2];
      platforms = platforms.unix;
    };
  }
