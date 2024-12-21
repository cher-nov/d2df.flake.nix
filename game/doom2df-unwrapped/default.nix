{
  lib,
  stdenv,
  autoPatchelfHook,
  fpc,
  enet,
  d2df-sdl,
  buildAsLibrary ? false,
  headless ? false,
  withHolmes ? false,
  disableIo ? true,
  withSDL1 ? false,
  SDL ? null,
  withSDL2 ? false,
  SDL2 ? null,
  disableGraphics ? true,
  libGL ? null,
  withOpenGLES ? false,
  withOpenGL2 ? false,
  disableSound ? true,
  withSoundStub ? false,
  withSDL1_mixer ? false,
  SDL_mixer ? null,
  withSDL2_mixer ? false,
  SDL2_mixer ? null,
  withOpenAL ? false,
  openal ? null,
  withVorbis ? false,
  libvorbis ? null,
  libogg ? null,
  withLibXmp ? false,
  libxmp ? null,
  withMpg123 ? false,
  libmpg123 ? null,
  withOpus ? false,
  libopus ? null,
  opusfile ? null,
  withGme ? false,
  game-music-emu ? null,
  withMiniupnpc ? false,
  miniupnpc ? null,
  withFluidsynth ? false,
  fluidsynth ? null,
  withModplug ? false,
  libmodplug ? null,
  withFmod ? false,
  ...
}: let
  optional = lib.optional;
  optionals = lib.optionals;
  version = "0.667";
  basename = "Doom2DF";
  src = d2df-sdl;

  sdlMixerFlag =
    if ((withSDL2_mixer && withSDL1) || (withSDL1_mixer && withSDL2))
    then abort "You can't mix different versions of SDL and SDL_Mixer."
    else if (withSDL1_mixer || withSDL2_mixer)
    then "-dUSE_SDLMIXER"
    else "";

  ioDriver = [
    (
      if ((withSDL1 && withSDL2) || (withSDL1 && disableIo) || (withSDL2 && disableIo))
      then abort "Exactly one system driver should be enabled (or none)."
      else if disableIo
      then "-dUSE_SYSSTUB"
      else if withSDL1
      then "-dUSE_SDL"
      else "-dUSE_SDL2"
    )
  ];
  soundDriver = [
    (
      if (lib.length (lib.filter (x: x == true) [withSDL2_mixer withSDL1_mixer withOpenAL withFmod disableSound]) > 1)
      then abort "Exactly one sound driver should be enabled (or none)."
      else if disableSound
      then "-dDISABLE_SOUND"
      else if withSoundStub
      then "-dUSE_SOUNDSTUB"
      else if withOpenAL
      then "-dUSE_OPENAL"
      else if withFmod
      then "-dUSE_FMOD"
      else sdlMixerFlag
    )
  ];
  renderDriver = [
    (
      if ((!withOpenGL2 && !disableGraphics && !withOpenGLES) || (withOpenGL2 && withOpenGLES) || (withOpenGL2 && disableGraphics) || (withOpenGLES && disableGraphics))
      then abort "Exactly one render driver should be enabled (or none)."
      else if (!withOpenGL2 && withHolmes)
      then abort "Holmes is supported only with desktop OpenGL."
      else if disableGraphics
      then "-dUSE_GLSTUB"
      else if withOpenGLES
      then "-dUSE_GLES1"
      else "-dUSE_OPENGL"
    )
  ];

  soundFileDrivers =
    if (!disableSound)
    then
      optional withVorbis "-dUSE_VORBIS"
      ++ optional withLibXmp "-dUSE_XMP"
      ++ optional withMpg123 "-dUSE_MPG123"
      ++ optional withOpus "-dUSE_OPUS"
      ++ optional withFluidsynth "-dUSE_FLUIDSYNTH"
      ++ optional withGme "-dUSE_GME"
      ++ optional withModplug "-dUSE_MODPLUG"
    else [];

  miscFlags =
    optional withHolmes "-dENABLE_HOLMES"
    ++ optional headless "-dHEADLESS"
    ++ optional withMiniupnpc "-dUSE_MINIUPNPC";

  defines =
    soundDriver
    ++ soundFileDrivers
    ++ ioDriver
    ++ renderDriver
    ++ miscFlags;

  soundActuallyUsed = !(disableSound || withSoundStub);
  #++ optimizationFlags;
in
  stdenv.mkDerivation rec {
    inherit version src;
    pname = "doom2df";
    name = "${pname}-${lib.optionalString buildAsLibrary "lib-"}${version}";

    patches = [];
    dontStrip = true;
    dontPatchELF = true;

    env = {
      D2DF_BUILD_USER = "nixbld";
      D2DF_BUILD_HASH = d2df-sdl.rev;
    };

    nativeBuildInputs =
      [
        fpc
        enet
      ]
      ++ optional withOpenAL openal
      ++ optional withSDL1 SDL
      ++ optional (soundActuallyUsed && withSDL1_mixer) SDL_mixer
      ++ optional withSDL2 SDL2
      ++ optional (soundActuallyUsed && withSDL2_mixer) SDL2_mixer
      ++ optional withLibXmp libxmp
      ++ optional (soundActuallyUsed && withMpg123) libmpg123
      ++ optionals (soundActuallyUsed && withOpus) [libopus opusfile]
      ++ optionals (soundActuallyUsed && withVorbis) [libvorbis libogg]
      ++ optionals (soundActuallyUsed && withFluidsynth) [fluidsynth]
      ++ optionals (soundActuallyUsed && withGme) [game-music-emu]
      ++ optionals (soundActuallyUsed && withModplug) [libmodplug]
      ++ optional withMiniupnpc miniupnpc;

    buildInputs =
      [
        enet
      ]
      ++ optional withSDL1 SDL
      ++ optional withSDL1_mixer SDL_mixer
      ++ optional withSDL2 SDL2
      ++ optional withSDL2_mixer SDL2_mixer
      ++ optional withOpenAL openal
      ++ optional (soundActuallyUsed && withLibXmp) libxmp
      ++ optional (soundActuallyUsed && withMpg123) libmpg123
      ++ optionals (soundActuallyUsed && withOpus) [libopus opusfile]
      ++ optionals (soundActuallyUsed && withVorbis) [libvorbis libogg]
      ++ optionals (soundActuallyUsed && withFluidsynth) [fluidsynth]
      ++ optionals (soundActuallyUsed && withModplug) [libmodplug]
      ++ optionals (soundActuallyUsed && withGme) [game-music-emu]
      ++ optional withMiniupnpc miniupnpc;

    buildPhase = ''
      pushd src/game
      mkdir bin tmp
      ${fpc}/bin/fpc \
        -FEbin -FUtmp \
        -al Doom2DF.lpr \
        ${(lib.concatStringsSep " " defines)} \
        ${let
        inputs = lib.filter (x: !builtins.isNull x) buildInputs;
      in
        lib.concatStringsSep " " (lib.map (x: "-Fl${x}/lib") inputs)} \
        ${
        if buildAsLibrary
        then "-olib${basename}.so"
        else "-o${basename}"
      }
      popd
    '';

    installPhase =
      if buildAsLibrary
      then ''
        mkdir -p $out/lib
        cp src/game/bin/lib${basename}.so $out/lib
      ''
      else ''
        mkdir -p $out/bin
        cp src/game/bin/${basename} $out/bin
      '';
  }
