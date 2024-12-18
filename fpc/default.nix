{
  wrapper = {
    fpc,
    fpcAttrs,
    writeShellScriptBin,
    lib,
    ...
  }:
    writeShellScriptBin "fpc" "PATH=\"$PATH:${lib.concatStringsSep ":" fpcAttrs.toolchainPaths}\" ${fpc}/bin/pp${fpcAttrs.basename} ${lib.concatStringsSep " " fpcAttrs.cpuArgs} ${fpcAttrs.targetArg} $@";

  base = {
    lib,
    stdenv,
    fetchgit,
    gawk,
    fpc,
    archsAttrs,
    binutils,
  }: let
    default = ["NOGDB=1" "FPC=\"${fpc}/bin/fpc\"" "PP=\"${fpc}/bin/fpc\"" "INSTALL_PREFIX=$out"];
  in
    stdenv.mkDerivation rec {
      version = "3.3.1";
      pname = "fpc-custom";
      src = fetchgit {
        url = "https://gitlab.com/freepascal.org/fpc/source.git";
        rev = "76e2ee99701b89837445a5b636d4507eb435f567";
        sha256 = "sha256-Uzcn1aPvekvEamIsPhP6VvZEWeK8RcUFtyFAqxgf4rQ=";
      };

      nativeBuildInputs = [binutils gawk fpc];
      glibc = stdenv.cc.libc.out;

      patches = [
        ./0001-Mark-paths-for-NixOS.patch
        ./allow-trunk.patch
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
        ''
          make all ${lib.concatStringsSep " " default}
        ''
        + (lib.concatStringsSep "\n" (
          lib.map (x: let
            abi = x.name;
            fpcAttrs = x.value;
          in ''
            PATH="$PATH:${lib.concatStringsSep ":" fpcAttrs.toolchainPaths}" \
              make crossall ${lib.concatStringsSep " " default} ${lib.concatStringsSep " " (lib.mapAttrsToList (name: value: "${name}=${value}") fpcAttrs.makeArgs)}
          '') (lib.attrsToList archsAttrs)
        ))
      );

      installPhase =
        (
          ''
            make install ${lib.concatStringsSep " " default}
          ''
          + (lib.concatStringsSep "\n" (
            lib.map (x: let
              abi = x.name;
              fpcAttrs = x.value;
            in ''
              PATH="$PATH:${lib.concatStringsSep ":" fpcAttrs.toolchainPaths}" \
                make crossinstall ${lib.concatStringsSep " " default} ${lib.concatStringsSep " " (lib.mapAttrsToList (name: value: "${name}=${value}") fpcAttrs.makeArgs)}
            '') (lib.attrsToList archsAttrs)
          ))
        )
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
}
