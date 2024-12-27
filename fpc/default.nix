{
  callPackage,
  fetchgit,
  stdenv,
  lib,
  pkgs,
}: let
  fpcDrv = {
    lib,
    stdenv,
    fetchgit,
    gawk,
    fpc,
    archsAttrs,
    glibc,
    binutils,
  }: let
    default = ["NOGDB=1" "FPC=\"${fpc}/bin/fpc\"" "PP=\"${fpc}/bin/fpc\"" "INSTALL_PREFIX=$out"];
  in
    stdenv.mkDerivation rec {
      version = "3.3.1";
      pname = "fpc";
      src = fetchgit {
        url = "https://gitlab.com/freepascal.org/fpc/source.git";
        rev = "a7dab71da1074b50ffd81e593537072869031242";
        sha256 = "sha256-JEH/TWNTxpbIBZ0JelqDb7FHZGm0j4O/No/8iFlxxAg=";
      };

      nativeBuildInputs = [binutils gawk fpc];
      glibc = stdenv.cc.libc.out;

      patches = [
        ./mark-paths-trunk.patch
      ];

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

      # At the moment of writing this comment, author couldn't find a way to
      # compile a crosscompiling FPC without compiling an FPC native to the host system.
      # So what we do, is first we compile the "native" FPC compiler, and then the compilers for architectures passed through.

      buildPhase = (
        (lib.concatStringsSep "\n" (
          lib.map (x: let
            abi = x.name;
            fpcAttrs = x.value;
          in ''
            PATH="$PATH:${lib.concatStringsSep ":" fpcAttrs.toolchainPaths}" \
              make crossall ${lib.concatStringsSep " " default} ${lib.concatStringsSep " " (lib.mapAttrsToList (name: value: "${name}=${value}") fpcAttrs.makeArgs)}
          '') (lib.attrsToList archsAttrs)
        ))
        + ''
          make all ${lib.concatStringsSep " " default}
        ''
      );

      installPhase =
        (lib.concatStringsSep "\n" (
          lib.map (x: let
            abi = x.name;
            fpcAttrs = x.value;
          in ''
            PATH="$PATH:${lib.concatStringsSep ":" fpcAttrs.toolchainPaths}" \
              make crossinstall ${lib.concatStringsSep " " default} ${lib.concatStringsSep " " (lib.mapAttrsToList (name: value: "${name}=${value}") fpcAttrs.makeArgs)}
          '') (lib.attrsToList archsAttrs)
        ))
        + ''
          make install ${lib.concatStringsSep " " default}
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
    };
in rec {
  fpcWrapper = {
    fpc,
    fpcAttrs,
    writeShellScriptBin,
    lib,
    ...
  }:
    writeShellScriptBin "fpc" "PATH=\"$PATH:${lib.concatStringsSep ":" fpcAttrs.toolchainPaths}\" ${fpc}/bin/pp${fpcAttrs.basename} ${lib.concatStringsSep " " fpcAttrs.cpuArgs} ${fpcAttrs.targetArg} $@";

  lazarusWrapper = {
    lazarus,
    fpc,
    fpcAttrs,
    writeShellScriptBin,
    lib,
    ...
  }:
    writeShellScriptBin "lazbuild" "PATH=\"$PATH:${lib.concatStringsSep ":" (["${fpc}/bin"] ++ fpcAttrs.toolchainPaths)}\" ${lazarus}/bin/lazbuild --lazarusdir=${lazarus}/share/lazarus --cpu=${fpcAttrs.makeArgs.CPU_TARGET} --os=${fpcAttrs.makeArgs.OS_TARGET}  $@";

  lazarus = {
    stdenv,
    lib,
    fetchgit,
    makeWrapper,
    writeText,
    fpc,
    gtk2,
    glib,
    pango,
    atk,
    gdk-pixbuf,
    libXi,
    xorgproto,
    libX11,
    libXext,
    withQt5 ? false,
    qtbase ? null,
    libqt5pas-git ? null,
    wrapQtAppsHook ? null,
    withGtk2 ? false,
    ...
  }:
  # TODO:
  #  1. the build date is embedded in the binary through `$I %DATE%` - we should dump that
  let
    version = "3.0.0-0";

    # as of 2.0.10 a suffix is being added. That may or may not disappear and then
    # come back, so just leave this here.
    majorMinorPatch = v:
      builtins.concatStringsSep "." (lib.take 3 (lib.splitVersion v));

    overrides = writeText "revision.inc" (lib.concatStringsSep "\n"
      (lib.mapAttrsToList (k: v: "const ${k} = '${v}';") {
        # this is technically the SVN revision but as we don't have that replace
        # it with the version instead of showing "Unknown"
        RevisionStr = version;
      }));
  in
    stdenv.mkDerivation rec {
      pname = "lazarus-git-8801ff3";
      inherit version;

      src = fetchgit {
        url = "https://gitlab.com/freepascal.org/lazarus/lazarus.git";
        rev = "lazarus_3_6";
        sha256 = "sha256-+ANj6rmK9QzgeEcnKOlejNi9FtCdtrHt24LcgszTNUE=";
      };

      postPatch = ''
        cp ${overrides} ide/${overrides.name}
      '';

      buildInputs =
        [
          # we need gtk2 unconditionally as that is the default target when building applications with lazarus
          fpc
          gtk2
          glib
          libXi
          xorgproto
          libX11
          libXext
          pango
          atk
          stdenv.cc
          gdk-pixbuf
        ]
        ++ lib.optionals withQt5 [libqt5pas-git qtbase];

      # Disable parallel build, errors:
      #  Fatal: (1018) Compilation aborted
      enableParallelBuilding = false;

      nativeBuildInputs = [makeWrapper] ++ lib.optional withQt5 wrapQtAppsHook;

      makeFlags = [
        "FPC=fpc"
        "PP=fpc"
        #"LAZARUS_INSTALL_DIR=${placeholder "out"}/share/lazarus/"
        "INSTALL_PREFIX=${placeholder "out"}/"
        "bigide"
      ];

      preBuild = ''
        mkdir -p $out/share/fpcsrc "$out/lazarus"
        cp -r ${fpc.src}/* $out/share/fpcsrc
        substituteInPlace ide/packages/ideconfig/include/unix/lazbaseconf.inc \
          --replace '/usr/fpcsrc' "$out/share/fpcsrc"
      '';

      meta = with lib; {
        description = "Graphical IDE for the FreePascal language";
        homepage = "https://www.lazarus.freepascal.org";
        license = licenses.gpl2Plus;
        maintainers = with maintainers; [raskin];
        platforms = platforms.linux;
      };
    };

  fpc-trunk = callPackage fpcDrv {archsAttrs = {};};
  fpc = fpc-trunk;

  fpc-3_2_2 = fpc.overrideAttrs (final: prev: {
    version = "3.2.2";
    src = fetchgit {
      url = "https://gitlab.com/freepascal.org/fpc/source.git";
      rev = "0d122c49534b480be9284c21bd60b53d99904346";
      sha256 = "sha256-MBrcthXl6awecRe8CnMpPmLAsVhdMZHQD8GBukiuqeE=";
    };

    patches = [./mark-paths-3_2_2.patch];
  });

  fpc-3_0_4 = let
    oldPkgs =
      import (fetchgit {
        name = "fpc-3_0_4-revision";
        url = "https://github.com/NixOS/nixpkgs/";
        sha256 = "sha256-RRx+Tk/PKKoTDZh9HDi7cOEHx6sI5zx1Puxv67zS9Ng=";
        rev = "b5e903cedb331f9ee268ceebffb58069f1dae9fb";
      }) {
        inherit (pkgs) system;
      };
  in
    oldPkgs.fpc;
}
