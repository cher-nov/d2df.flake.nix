{
  lib,
  callPackage,
  buildWad,
  mkAssetsPath,
  doom2df-res,
  executablesAttrs,
  mkExecutablePath,
  mkGamePath,
  mkAndroidApk,
  androidRoot,
  androidRes,
  dirtyAssets,
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
    inherit (dirtyAssets) flexuiWad botlist botnames;
  };
  createBundlesAndExecutables = lib.mapAttrs (arch: archAttrs: let
    info = archAttrs.infoAttrs.d2dforeverFeaturesSuport;

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
        NoSound = archAttrs: true;
      };
      headless = {
        Enable = archAttrs: info.supportsHeadless;
        Disable = archAttrs: true;
      };
      holmes = {
        Enable = archAttrs: info.openglDesktop;
        Disable = archAttrs: true;
      };
    };
    featuresMatrix = features: archAttrs: let
      prepopulatedFeatureAttrs = lib.mapAttrs (featureName: featureAttrs: (lib.mapAttrs (definition: value: (value archAttrs) == true)) featureAttrs) features;
      filteredFeatureAttrs = lib.mapAttrs (featureName: featureAttrs: (lib.filterAttrs (definition: value: value == true) featureAttrs)) prepopulatedFeatureAttrs;
      zippedFeaturesWithPossibleValues = lib.mapAttrs (feature: featureAttrset: (lib.foldlAttrs (acc: definitionName: definitionValue: acc ++ [definitionName]) [] featureAttrset)) filteredFeatureAttrs;
      featureCombinations = lib.cartesianProduct zippedFeaturesWithPossibleValues;
    in
      # TODO
      # Get some filters here.
      # Maybe sound == SDL2 && io != SDL2?
      lib.filter (
        combo:
          !(
            (combo.holmes == "Enable" && combo.graphics != "OpenGL2")
            || (combo.holmes == "Enable" && combo.io != "SDL2")
            #|| (combo.io == "sysStub" && combo.headless == "disable")
            #|| (combo.sound == "SDL2_mixer" && combo.io != "SDL2")
            #|| (combo.sound == "SDL" && combo.io != "SDL2")
          )
      )
      featureCombinations;
    mkExecutable = doom2d: featureAttrs @ {
      graphics,
      headless,
      io,
      sound,
      holmes,
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
        else if x == "NoSound"
        then {disableSound = true;}
        else builtins.throw "Unknown build flag";
      headlessFeature = let
        x = headless;
      in
        if x == "Enable"
        then {headless = true;}
        else if x == "Disable"
        then {headless = false;}
        else builtins.throw "Unknown build flag";
      holmesFeature = let
        x = holmes;
      in
        if x == "Enable"
        then {withHolmes = true;}
        else if x == "Disable"
        then {withHolmes = false;}
        else builtins.throw "Unknown build flag";
    in {
      value = {
        drv = doom2d.override ({
            inherit headless;
            buildAsLibrary = info.loadedAsLibrary;
          }
          // ioFeature
          // graphicsFeature
          // soundFeature
          // headlessFeature
          // holmesFeature);
        defines = {
          inherit graphics headless sound holmes io;
        };
        pretty = "Doom2D Forever for ${archAttrs.infoAttrs.pretty}: ${io}, ${sound}, ${graphics}${lib.optionalString (holmes == "Enable")  ", with Holmes"}${lib.optionalString (headless == "Enable") ", headless"}";
      };
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
        headlessStr = lib.optionalString (headless == "Enable") "-headless";
        holmesStr = lib.optionalString (holmes == "Enable") "-holmes";
      in "doom2df-${archAttrs.infoAttrs.name}${ioStr}${soundStr}${graphicsStr}${headlessStr}${holmesStr}";
    };
    matrix = featuresMatrix features archAttrs;
    allCombos = lib.listToAttrs (lib.map (x: mkExecutable archAttrs.doom2d x) matrix);
    defaultExecutable = (builtins.head (lib.attrValues (lib.filterAttrs (n: v: v.defines == archAttrs.infoAttrs.bundle) allCombos))).drv;
    executables = allCombos;
    bundles = lib.recursiveUpdate {} (lib.optionalAttrs (!info.loadedAsLibrary) {
      default = callPackage mkGamePath {
        gameExecutablePath = callPackage mkExecutablePath rec {
          byArchPkgsAttrs = {
            "${arch}" = {
              sharedLibraries = lib.map (drv: drv.out) executables.default.buildInputs;
              doom2df = executables.default;
              editor = archAttrs.editor;
              isWindows = archAttrs.infoAttrs.isWindows;
              asLibrary = info.loadedAsLibrary;
              prefix = ".";
            };
          };
        };
        gameAssetsPath = defaultAssetsPath;
      };
    });
  in {
    __archPkgs = archAttrs;
    inherit defaultExecutable executables bundles;
  });
in
  (createBundlesAndExecutables executablesAttrs)
  // {
    android = let
      # FIXME
      # Just find something with "android" as prefix instead of hardcoding it
      sdk = executablesAttrs.android-arm64-v8a.androidSdk;
      sdl = executablesAttrs.android-arm64-v8a.SDL2;
      gameExecutablePath = callPackage mkExecutablePath {
        byArchPkgsAttrs =
          lib.mapAttrs (arch: archAttrs: let
            doom2d = archAttrs.doom2d.override {
              withSDL2 = true;
              withSDL2_mixer = true;
              withVorbis = true;
              withFluidsynth = true;
              withLibXmp = true;
              withMpg123 = true;
              withOpus = true;
              withGme = true;
              withOpenGLES = true;
              buildAsLibrary = true;
            };
          in {
            sharedLibraries = lib.map (drv: drv.out) doom2d.buildInputs;
            # FIXME
            # Android version is hardcoded
            doom2df = lib.trace "${doom2d}" doom2d;
            isWindows = false;
            asLibrary = true;
            editor = null;
            prefix = "${archAttrs.infoAttrs.androidAbi}";
          })
          (lib.filterAttrs (n: v: lib.hasPrefix "android" n) executablesAttrs);
      };
    in {
      bundles = {
        inherit gameExecutablePath;
        default = mkAndroidApk {
          androidSdk = sdk;
          SDL2ForJava = sdl;
          gameAssetsPath = defaultAssetsPath;
          inherit androidRoot androidRes gameExecutablePath;
        };
      };
      executables = {};
    };
  }
