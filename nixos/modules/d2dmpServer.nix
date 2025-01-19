{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.d2dmp;

  xorgDisplayNumber = "53";
  userDir = "/var/lib/d2dmp";
  user = "d2dmultiplayer";
  group = "d2dmultiplayer";

  updated_exe = pkgs.fetchurl {
    url = "https://github.com/polybluez/filedump/releases/download/Tag2/130_sv_but_with_synctype_fix.exe";
    sha256 = "sha256-CsqA1rOkvjQX5iapc8okwreVN7o5n9L6VDCb4j4BqxE=";
  };

  d2dmpData = {
    lib,
    stdenvNoCC,
    fetchurl,
    unzip,
    fd,
  }: let
    baseName = "D2DMP_0.6(130)_FULL";
  in
    stdenvNoCC.mkDerivation rec {
      pname = "d2dmp-data";
      version = "1.0";

      src = fetchurl {
        url = "https://github.com/polybluez/filedump/releases/download/Tag1/D2DMP_0.6.130._FULL.zip";
        sha256 = "sha256-FUfSMttzC24MPeEoF1G3DKg6KBpn5+vKnWCjpX0zc4A=";
      };

      nativeBuildInputs = [unzip fd];

      unpackPhase = ''
        runHook preUnpack

        unzip -q ${src}
        mkdir -p "$out"
        mv '${baseName}'/* "$out"

        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall

        runHook postInstall
      '';

      meta = with lib; {
        homepage = "https://doom2d.org";
        description = "Doom 2D Multiplayer game data";
        license = licenses.unfree;
        maintainers = [];
        platforms = platforms.all;
      };
    };
in {
  options.services.d2dmp = {
    enable = (lib.mkEnableOption "Doom2D Multiplayer servers") // {default = true;};
    wine = lib.mkPackageOption pkgs "wineWow64Packages.stable" {};
    openFirewall = (lib.mkEnableOption "Doom2D Multiplayer servers") // {default = true;};
    settings = lib.mkOption {
      description = ''
        Generates the `server.cfg` file.
      '';

      default = {};

      type = lib.types.submodule {
        freeformType = with lib.types; let
          scalars = oneOf [singleLineStr int float];
        in
          attrsOf (oneOf [scalars (nonEmptyListOf scalars)]);
      };
    };
    autoexec = lib.mkOption {
      description = ''
        Generates the `autoexec.cfg` file. Commands from this file will be run at a new round.
      '';

      default = "";
      type = lib.types.lines;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      cfg.settings.sv_port
    ];

    users.users."${user}" = {
      description = "Doom2D Multiplayer service user";
      isSystemUser = true;
      inherit group;
    };
    users.groups."${group}" = {};
    systemd = let
      abbr = "d2dmp";
      name = "deathmatch";
      serverServiceName = "${abbr}-${name}";
      xdummyServiceName = "${abbr}-xdummy";
      dataPackage = d2dmpData;
      mkXdummyService = let
        inherit (pkgs) writeText xorg xkeyboard_config writeShellScriptBin;
        megabytes = bytes: builtins.toString (bytes * 1000);
        xorgConfig = writeText "dummy-xorg.conf" ''
          Section "ServerLayout"
            Identifier     "dummy_layout"
            Screen         0 "dummy_screen"
            InputDevice    "dummy_keyboard" "CoreKeyboard"
            InputDevice    "dummy_mouse" "CorePointer"
          EndSection

          Section "ServerFlags"
            Option "DontVTSwitch" "true"
            Option "AllowMouseOpenFail" "true"
            Option "PciForceNone" "true"
            Option "AutoEnableDevices" "false"
            Option "AutoAddDevices" "false"
          EndSection

          Section "Files"
            ModulePath "${xorg.xorgserver.out}/lib/xorg/modules"
            ModulePath "${xorg.xf86videodummy}/lib/xorg/modules"
            XkbDir "${xkeyboard_config}/share/X11/xkb"
            FontPath "${xorg.fontadobe75dpi}/lib/X11/fonts/75dpi"
            FontPath "${xorg.fontadobe100dpi}/lib/X11/fonts/100dpi"
            FontPath "${xorg.fontmiscmisc}/lib/X11/fonts/misc"
            FontPath "${xorg.fontcursormisc}/lib/X11/fonts/misc"
          EndSection

          Section "Module"
            Load           "dbe"
            Load           "extmod"
            Load           "freetype"
            Load           "glx"
          EndSection

          Section "InputDevice"
            Identifier     "dummy_mouse"
            Driver         "void"
          EndSection

          Section "InputDevice"
            Identifier     "dummy_keyboard"
            Driver         "void"
          EndSection

          Section "Monitor"
            Identifier     "dummy_monitor"
            HorizSync       30.0 - 130.0
            VertRefresh     50.0 - 250.0
            Option         "DPMS"
          EndSection

          Section "Device"
            Identifier     "dummy_device"
            Driver         "dummy"
            VideoRam       ${megabytes 1}
          EndSection

          Section "Screen"
            Identifier     "dummy_screen"
            Device         "dummy_device"
            Monitor        "dummy_monitor"
            DefaultDepth    24
            SubSection     "Display"
              Depth       24
              Modes      "1x1"
            EndSubSection
          EndSection
        '';
        xdummy = writeShellScriptBin "xdummy" ''
          exec ${xorg.xorgserver.out}/bin/Xorg \
            -noreset \
            -logfile /dev/null \
            "$@" \
            -config "${xorgConfig}"
        '';
      in {
        description = "Xdummy server for Doom2D Multiplayer game servers";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        serviceConfig.ExecStart = ''
          ${xdummy}/bin/xdummy :${xorgDisplayNumber} +extension GLX
        '';
      };
      printSettings = settingsAttr:
        builtins.concatStringsSep "\n" (
          lib.mapAttrsToList (
            key: option: let
              escape = s: lib.replaceStrings ["\""] ["'"] s;
              quote = s: "${s}";

              toValue = x: let
                quoteFunc =
                  if lib.typeOf x == "int" || builtins.typeOf x == "float"
                  then lib.id
                  else quote;
              in
                quoteFunc (escape (toString x));

              value = (
                if lib.isList option
                then
                  builtins.concatStringsSep
                  ","
                  (builtins.map (x: toValue x) option)
                else toValue option
              );
            in "${key} ${value}"
          )
          settingsAttr
        );
      mkServerService = name: {
        description = "Doom2D Forever server instance ‘${name}’";
        wantedBy = ["multi-user.target"];
        after = ["network.target" "${xdummyServiceName}.service"];
        requires = ["network.target" "${xdummyServiceName}.service"];
        # zenity pulls GTK4, which is a very big dependency
        path = [cfg.wine pkgs.coreutils (pkgs.winetricks.override {zenity = null;}) pkgs.xdotool pkgs.xorg.xwininfo pkgs.gawk];
        environment = {
          WINEPREFIX = "${userDir}/wine";
          XDG_RUNTIME_DIR = "";
          DISPLAY = ":${xorgDisplayNumber}";
          WINEDLLOVERRIDES = "d3d8=n";
        };
        serviceConfig.User = user;

        serviceConfig = {
          CPUAccounting = true;
          MemoryAccounting = true;
          MemoryHigh = 500 * 1024 * 1024; # 500 MB
          MemoryMax = 600 * 1024 * 1024; # 600 MB
          TasksAccounting = true;
          IOAccounting = true;
          Nice = 19;
          IOSchedulingPriority = 7;
        };

        serviceConfig = {
          NoNewPrivileges = true;
          DevicePolicy = "closed";
          ProtectSystem = true;
          ProtectHome = true;
          ProtectControlGroups = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          PrivateUsers = true;
          ProtectKernelLogs = true;
          PrivateMounts = true;
          ProtectHostname = true;
          PrivateTmp = true;
          #TemporaryFileSystem = "/:ro";
          #BindPaths = baseDir;
          #BindReadOnlyPaths = doom2df-data;
        };
        #serviceConfig.StandardOutput = "null";
        #serviceConfig.StandardError = "null";

        serviceConfig.LogFilterPatterns = [
          # With a dummy ALSA sound device, there is a lot of spam with "underrun detected" messages
          "~Underrun detected"
          # xwininfo prints this, even though everything works OK
          #"~XGetInputFocus returned"
        ];

        # Restart every 6 hours, because the game server will die over time.
        serviceConfig.Restart = "always";
        serviceConfig.RuntimeMaxSec = "6h";

        serviceConfig.ExecStart = let
          exe = "130_sv_but_with_synctype_fix.exe";
          configFile = let
            src = pkgs.writeText "${abbr}-server.cfg" (printSettings cfg.settings);
            converted = convertToWin1251 src;
          in
            converted;
          autoExec = let
            src = pkgs.writeText "${abbr}-autoexec.cfg" cfg.autoexec;
            converted = convertToWin1251 src;
          in
            converted;
          launchCmd = "wine ${userDir}/${exe} -nogui -q";
          convertToWin1251 = x: let
            drv =
              pkgs.runCommandLocal "win1251-convert" {
                nativeBuildInputs = [pkgs.iconv pkgs.coreutils];
              } ''
                mkdir -p $out
                iconv -f UTF-8 -t WINDOWS-1251 -o "$out/str" ${x}
              '';
          in
            drv;
          closeErrorWindowScript =
            pkgs.writeShellScriptBin "close-error-window"
            # 3 times sleep for 10s, see if there is a nag about audio devices, close it
            ''
              sleep 20s
              for i in 1..3; do
                sleep 3s;
                ERROR_WINDOW=$(xwininfo -root -tree | grep "Error Messages" | awk '{print $1}')
                xdotool key --window $ERROR_WINDOW enter
                sleep 7s;
              done
            '';
          # nix-store -q --referrers-closure /nix/store/dp2c6lh3mj8kx1l1520ackwjw8y9r400-gtk4-4.16.3/
          script =
            pkgs.writeShellScriptBin "d2dmp-run"
            (
              ''
                mkdir -p "${userDir}/wine"
                cd "${userDir}"
                cp ${dataPackage}/* "${userDir}" -r
                cp "${updated_exe}" ${exe}
                cp "${./d3d8.dll}" "${userDir}/d3d8.dll"
                chmod 700 -R ${userDir}
              ''
              + ''
                rm ${userDir}/data/cfg/autoexec.cfg
                cat "${autoExec}/str" > "${userDir}/data/cfg/autoexec.cfg"

                rm ${userDir}/data/cfg/server.cfg
                cat "${configFile}/str" > "${userDir}/data/cfg/server.cfg"
              ''
              # Backup old logs.
              + ''
                [[ -f ${userDir}/data/logs/server.log ]] && cp --backup=t ${userDir}/data/logs/server.log ${userDir}/data/logs/server.old.log
              ''
              # First, initialize the prefix. Unset DISPLAY so that WINE doesn't offer to install Mono and other things with a graphical dialog.
              # Wait a bit, and then try to launch the game server process with DISPLAY unset. It makes sure everything from WINE is copied to the prefix.
              # Then, kill the old game server process if it exists and then disable the crash dialog, and launch the server again.
              + ''
                DISPLAY= wineboot
                DISPLAY= ${launchCmd} &
                sleep 5s
                DISPLAY= wine taskkill /f /im ${exe}
                sleep 1s
                winetricks nocrashdialog
                ${closeErrorWindowScript}/bin/close-error-window &
                ${launchCmd}
              ''
            );
        in "${script}/bin/d2dmp-run";
      };
    in {
      services."${xdummyServiceName}" = mkXdummyService;
      services."${serverServiceName}" = mkServerService name;

      tmpfiles.rules = [
        # Recursively change owner to Doom2D Multiplayer service user
        "d '${userDir}' 0700 ${user} ${group} - -"
        "Z '${userDir}' 0700 ${user} ${group} - -"
      ];
    };
  };
}
