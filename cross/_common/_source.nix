{pins}: {cmakeDrv}: {
  SDL2 = cmakeDrv {
    pname = "SDL2";
    version = pins.SDL2.version;
    src = pins.SDL2.src;
    licenseFiles = ["${pins.SDL2.src}/LICENSE.txt"];
  };

  enet = cmakeDrv {
    pname = "enet";
    version = pins.enet.version;
    src = pins.enet.src;
    licenseFiles = ["${pins.enet.src}/LICENSE"];
  };

  SDL2_mixer = cmakeDrv {
    pname = "SDL2_mixer";
    version = pins.SDL2_mixer.version;
    src = pins.SDL2_mixer.src;
    licenseFiles = ["${pins.SDL2_mixer.src}/LICENSE.txt"];
  };

  # Upstream packaging is horrendous.
  opusfile = cmakeDrv {
    pname = "opusfile";
    version = pins.opusfile.version;
    src = pins.opusfile.src;
    licenseFiles = ["${pins.opusfile.src}/COPYING"];
  };

  libogg = cmakeDrv {
    pname = "libogg";
    version = pins.libogg.version;
    src = pins.libogg.src;
    licenseFiles = ["${pins.libogg.src}/COPYING"];
  };

  libopus = cmakeDrv {
    pname = "opus";
    version = pins.libopus.version;
    src = pins.libopus.src;
    licenseFiles = ["${pins.libopus.src}/COPYING"];
  };

  libxmp = cmakeDrv {
    pname = "libxmp";
    version = pins.libxmp.version;
    src = pins.libxmp.src;
    licenseFiles = ["${pins.libxmp.src}/README"];
  };

  fluidsynth = cmakeDrv {
    pname = "fluidsynth";
    version = pins.fluidsynth.version;
    src = pins.fluidsynth.src;
    licenseFiles = ["${pins.fluidsynth.src}/LICENSE"];
  };

  wavpack = cmakeDrv {
    pname = "wavpack";
    version = pins.wavpack.version;
    src = pins.wavpack.src;
    licenseFiles = ["${pins.wavpack.src}/COPYING"];
  };

  libmpg123 = cmakeDrv {
    pname = "mpg123";
    version = pins.libmpg123.version;
    src = pins.libmpg123.src;
    licenseFiles = ["${pins.libmpg123.src}/COPYING"];
  };

  libvorbis = cmakeDrv {
    pname = "vorbis";
    version = pins.libvorbis.version;
    src = pins.libvorbis.src;
    licenseFiles = ["${pins.libvorbis.src}/COPYING"];
  };

  game-music-emu = cmakeDrv {
    pname = "game-music-emu";
    version = pins.game-music-emu.version;
    src = pins.game-music-emu.src;
    licenseFiles = ["${pins.game-music-emu.src}/license.txt"];
  };

  libmodplug = cmakeDrv {
    pname = "libmodplug";
    version = pins.libmodplug.version;
    src = pins.libmodplug.src;
    licenseFiles = ["${pins.libmodplug.src}/COPYING"];
  };

  openal = cmakeDrv {
    pname = "openal-soft";
    version = pins.openal.version;
    src = pins.openal.src;
    licenseFiles = ["${pins.openal.src}/COPYING"];
  };

  miniupnpc = cmakeDrv {
    pname = "miniupnpc";
    version = pins.miniupnpc.version;
    src = "${pins.miniupnpc.src}/miniupnpc";
    licenseFiles = ["${pins.miniupnpc.src}/miniupnpc/LICENSE"];
  };
}
