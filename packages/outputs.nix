{
  lib,
  callPackage,
  buildWad,
  mkAssetsPath,
  doom2df-res,
  executablesAttrs,
}: let
  wads = lib.listToAttrs (lib.map (wad: {
    name = wad;
    value = callPackage buildWad {
      outName = wad;
      lstPath = "${wad}.lst";
      inherit doom2df-res;
    };
  }) ["game" "editor" "shrshade" "standart" "doom2d" "doomer"]);
  defaultAssetsPath = mkAssetsPath {
    doom2dWad = wads.doom2d;
    doomerWad = wads.doomer;
    standartWad = wads.standart;
    shrshadeWad = wads.shrshade;
    gameWad = wads.game;
    editorWad = wads.editor;
    # FIXME
    # Dirty, hardcoded assets
    flexuiWad = ./game/assets/dirtyAssets/flexui.wad;
    botlist = ./game/assets/dirtyAssets/botlist.txt;
    botnames = ./game/assets/dirtyAssets/botnames.txt;
  };
in
  lib.mapAttrs (arch: archAttrs: let
    info = archAttrs.infoAttrs.d2dforeverFeaturesSuport;
    executables = let
      features = {
        io = {
          SDL1 = archAttrs: archAttrs ? "SDL1";
          SDL2 = archAttrs: archAttrs ? "SDL2";
          sysStub = archAttrs: info.supportsHeadless;
        };
        graphics = {
          OpenGL2 = archAttrs: info.openglDesktop;
          OpenGLES = archAttrs: info.openglEs;
          GLStub = archAttrs: info.supportsHeadless;
        };
        sound = {
          FMOD = archAttrs: archAttrs ? "fmodex";
          SDL_mixer = archAttrs: archAttrs ? "SDL_mixer";
          SDL2_mixer = archAttrs: archAttrs ? "SDL2_mixer";
          OpenAL = archAttrs: archAttrs ? "openal";
          disable = archAttrs: true;
        };
        headless = {
          isHeadless = archAttrs: info.supportsHeadless;
          isNotHeadless = archAttrs: true;
        };
      };
      featuresMatrix = features: archAttrs: let
        prepopulatedFeatureAttrs = lib.mapAttrs (featureName: featureAttrs: (lib.mapAttrs (definition: value: (value archAttrs) == true)) featureAttrs) features;
        filteredFeatureAttrs = lib.mapAttrs (featureName: featureAttrs: (lib.filterAttrs (definition: value: value == true) featureAttrs)) prepopulatedFeatureAttrs;
        zippedFeaturesWithPossibleValues = lib.mapAttrs (feature: featureAttrset: (lib.foldlAttrs (acc: definitionName: definitionValue: acc ++ [definitionName]) [] featureAttrset)) filteredFeatureAttrs;
      in
        lib.cartesianProduct zippedFeaturesWithPossibleValues;
      mkExecutable = doom2d: featureAttrs @ {
        graphics,
        headless,
        io,
        sound,
      }: let
        ioFeature = let
          x = io;
        in
          if x == "SDL1"
          then {withSDL1 = true;}
          else if x == "SDL2"
          then {withSDL2 = true;}
          else if x == "sysStub"
          then {disableIo = true;}
          else builtins.throw "Unknown build flag";
        graphicsFeature = let
          x = graphics;
        in
          if x == "OpenGL2"
          then {withOpenGL2 = true;}
          else if x == "OpenGLES"
          then {withOpenGLES = true;}
          else if x == "GLStub"
          then {disableGraphics = true;}
          else builtins.throw "Unknown build flag";
        soundFeature = let
          x = sound;
        in
          if x == "FMOD"
          then {withFmod = true;}
          else if x == "SDL_mixer"
          then {withSDL1_mixer = true;}
          else if x == "SDL2_mixer"
          then {withSDL2_mixer = true;}
          else if x == "OpenAL"
          then {withOpenAL = true;}
          else if x == "disable"
          then {disableSound = true;}
          else builtins.throw "Unknown build flag";
        headlessFeature = let
          x = headless;
        in
          if x == "isHeadless"
          then {headless = true;}
          else if x == "isNotHeadless"
          then {headless = false;}
          else builtins.throw "Unknown build flag";
      in {
        value = doom2d.override ({
            inherit headless;
          }
          // ioFeature
          // graphicsFeature
          // soundFeature
          // headlessFeature);
        name = let
          soundStr =
            if sound == "disable"
            then "-NoSound"
            else "-${sound}";
          ioStr =
            if io == "sysStub"
            then "-IOStub"
            else "-${io}";
          graphicsStr = "-${graphics}";
          headlessStr = lib.optionalString (headless == "isHeadless") "-headless";
        in "doom2df-${archAttrs.infoAttrs.name}${ioStr}${soundStr}${graphicsStr}${headlessStr}";
      };
    in
      {
        lol = archAttrs;
      }
      // (let matrix = featuresMatrix features archAttrs; in lib.listToAttrs (lib.map (x: mkExecutable archAttrs.doom2d x) matrix));
    bundles = {};
  in {
    inherit executables bundles;
  })
  executablesAttrs
