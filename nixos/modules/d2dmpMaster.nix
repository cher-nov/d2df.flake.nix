{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.d2dmpMasterServer;
in {
  options = {
    services.d2dmpMasterServer = {
      enable = lib.mkEnableOption "Doom2D Forever master server";
      openFirewall = lib.mkEnableOption "open firewall ports" // {default = true;};
      package = lib.mkPackageOption pkgs "doom2d-multiplayer-master-server" {};
      port = lib.mkOption {
        type = lib.types.port;
        default = 25667;
        description = ''
          Port which master server will listen on.
        '';
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["-v"];
        description = ''
          Extra arguments to launch master server with.
        '';
      };
    };
  };
  config = let
    usageLimitAttrs = {
      CPUAccounting = true;
      MemoryAccounting = true;
      MemoryHigh = 16 * 1024 * 1024;
      MemoryMax = 32 * 1024 * 1024;
      TasksAccounting = true;
      IOAccounting = true;
    };
    hardeningAttrs = {
      NoNewPrivileges = true;
      PrivateDevices = true;
      DevicePolicy = true;
      ProtectSystem = true;
      ProtectHome = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictAddressFamilies = "AF_INET AF_INET6 AF_NETLINK";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      MemoryDenyWriteExecute = true;
      LockPersonality = true;
      # breaks CAP_NET_BIND_SERVICE if enabled
      PrivateUsers = !isOnLowerPort;
      ProtectKernelLogs = true;
      PrivateMounts = true;
      ProtectHostname = true;
      PrivateTmp = true;
      #TemporaryFileSystem = "/:ro";
      #BindPaths = [stateDir];
      #BindReadOnlyPaths = ["/nix/store"];

      # Net
      SecureBits = lib.optionalString isOnLowerPort "keep-caps";
      AmbientCapabilities = lib.optionals isOnLowerPort ["CAP_NET_BIND_SERVICE" "CAP_NET_ADMIN"];
      CapabilityBoundingSet = lib.optionals isOnLowerPort ["CAP_NET_BIND_SERVICE" "CAP_NET_ADMIN"];
      SocketBindDeny = "any";
      SocketBindAllow = ["tcp:${builtins.toString cfg.port}"];
    };
    exec = pkgs.writeShellScript "d2dmp_master" ''
      cd ${stateDir}
      python ${cfg.package} -p ${builtins.toString cfg.port} ${lib.concatStringsSep " " cfg.extraArgs}
    '';
    user = "d2dmpmaster";
    socket = "${serviceName}.socket";
    isOnLowerPort = cfg.port < 1024;
    stateDir = "/var/lib/d2dmp_master";
    serviceName = "d2dmp-master-server";
  in {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];

    users.users."${user}" = {
      description = "Doom2D Multiplayer master server user";
      isSystemUser = true;
      group = user;
    };
    users.groups."${user}" = {};
    systemd = {
      tmpfiles.rules = [
        # Recursively change owner to Doom2D Forever service user
        "d '${stateDir}' 0700 ${user} - - -"
        "Z '${stateDir}' 0700 ${user} - - -"
      ];
      sockets."${serviceName}" = {
        socketConfig = {
          ListenFIFO = "%t/${serviceName}.stdin";
          Service = "${serviceName}.service";
        };
      };
      services."${serviceName}" = {
        description = "Doom2D Multiplayer master server";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        path = [pkgs.python2];
        serviceConfig =
          {
            ExecStart = exec;
            Restart = "always";
            Type = "simple";
            Sockets = [socket];
            StandardInput = "socket";
            StandardOutput = "journal";
            StandardError = "journal";
            User = user;
            Group = user;
          }
          // hardeningAttrs
          // usageLimitAttrs;
      };
    };
  };
}
