{pins}: {cmakeDrv}: {
  SDL2 = cmakeDrv {
    pname = "SDL2";
    version = pins.SDL2.version;
    src = pins.SDL2.src;
  };

  enet = cmakeDrv {
    pname = "enet";
    version = pins.enet.version;
    src = pins.enet.src;
  };

  SDL2_mixer = cmakeDrv {
    pname = "SDL2_mixer";
    version = pins.SDL2_mixer.version;
    src = pins.SDL2_mixer.src;
  };

  # Upstream packaging is horrendous.
  opusfile = cmakeDrv {
    pname = "opusfile";
    version = pins.opusfile.version;
    src = pins.opusfile.src;
  };

  libogg = cmakeDrv {
    pname = "libogg";
    version = pins.libogg.version;
    src = pins.libogg.src;
  };

  libopus = cmakeDrv {
    pname = "opus";
    version = pins.libopus.version;
    src = pins.libopus.src;
  };

  libxmp = cmakeDrv {
    pname = "libxmp";
    version = pins.libxmp.version;
    src = pins.libxmp.src;
  };

  fluidsynth = cmakeDrv {
    pname = "fluidsynth";
    version = pins.fluidsynth.version;
    src = pins.fluidsynth.src;
  };

  wavpack = cmakeDrv {
    pname = "wavpack";
    version = pins.wavpack.version;
    src = pins.wavpack.src;
  };

  libmpg123 = cmakeDrv {
    pname = "mpg123";
    version = pins.libmpg123.version;
    src = pins.libmpg123.src;
  };

  libvorbis = cmakeDrv {
    pname = "vorbis";
    version = pins.libvorbis.version;
    src = pins.libvorbis.src;
  };

  game-music-emu = cmakeDrv {
    pname = "game-music-emu";
    version = pins.game-music-emu.version;
    src = pins.game-music-emu.src;
  };

  libmodplug = cmakeDrv {
    pname = "libmodplug";
    version = pins.libmodplug.version;
    src = pins.libmodplug.src;
  };

  openal = cmakeDrv {
    pname = "openal-soft";
    version = pins.openal.version;
    src = pins.openal.src;
  };
}
