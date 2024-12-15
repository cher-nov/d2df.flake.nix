{
  lib,
  stdenv,
  fetchgit,
  gawk,
  fpc,
  androidNdk,
  androidPlatform
}: let
  startFPC = fpc;
in
  stdenv.mkDerivation rec {
    version = "3.3.1";
    pname = "fpc-android";
    src = fetchgit {
      url = "https://gitlab.com/freepascal.org/fpc/source.git";
      rev = "bea36238e7ed10caf56df832ed070f569d6892f3";
      sha256 = "sha256-IWuz+a2GwzxGanGgC6LMeAtW/TvER225AnfBBvXmses=";
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
      ndkToolchainAarch = "${androidNdk}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin";
      ndkToolchainArm32 = "${androidNdk}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin";
      ndkLibArm32 = "${androidNdk}/platforms/android-${androidPlatform}/arch-arm/usr/lib";
      ndkLibAarch = "${androidNdk}/platforms/android-${androidPlatform}/arch-arm64/usr/lib";
    in ''
      export PATH="$PATH:${ndkToolchainArm32}:${ndkToolchainAarch}";
      #export PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH";
      make clean all
      make clean all OS_TARGET=android CPU_TARGET=aarch64 CROSSOPT="-Fl${ndkLibAarch}" NDK=${androidNdk} NOGDB=1 FPC="${fpc}/bin/fpc" PP="${fpc}/bin/fpc" INSTALL_PREFIX=$out
      make clean all OS_TARGET=android CPU_TARGET=arm CROSSOPT="-CpARMV7A -CfVFPV3 -Fl${ndkLibArm32}" NDK=${androidNdk} NOGDB=1 FPC="${fpc}/bin/fpc" PP="${fpc}/bin/fpc" INSTALL_PREFIX=$out
    '';

    installPhase =
      ''
        make install NOGDB=1 INSTALL_PREFIX=$out
        make crossinstall NOGDB=1 OS_TARGET=android CPU_TARGET=aarch64 INSTALL_PREFIX=$out
        make crossinstall NOGDB=1 OS_TARGET=android CPU_TARGET=arm INSTALL_PREFIX=$out
      ''
      + ''
        for i in $out/lib/fpc/*/ppc*; do
          ln -fs $i $out/bin/$(basename $i)
        done

        mkdir -p $out/lib/fpc/etc/
        $out/lib/fpc/*/samplecfg $out/lib/fpc/${version} $out/lib/fpc/etc/

        # Generate config files in /etc since on darwin, ppc* does not follow symlinks
        # to resolve the location of /etc
        mkdir -p $out/etc
        $out/lib/fpc/*/samplecfg $out/lib/fpc/${version} $out/etc
      '';

    meta = with lib; {
      description = "Free Pascal Compiler from a source distribution";
      homepage = "https://www.freepascal.org";
      maintainers = [maintainers.raskin];
      license = with licenses; [gpl2 lgpl2];
      platforms = platforms.unix;
    };
  }
