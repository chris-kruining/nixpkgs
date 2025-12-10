{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.sabnzbd;
  inherit (pkgs) sabnzbd;
in {
  ###### interface

  options = {
    services.sabnzbd = {
      enable = mkEnableOption "the sabnzbd server";

      package = mkPackageOption pkgs "sabnzbd" {};

      configFile = mkOption {
        type = types.path;
        default = "/var/lib/sabnzbd/sabnzbd.ini";
        description = "Path to config file.";
      };

      user = mkOption {
        default = "sabnzbd";
        type = types.str;
        description = "User to run the service as";
      };

      group = mkOption {
        type = types.str;
        default = "sabnzbd";
        description = "Group to run the service as";
      };

      host = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = ''
          The hostname that will be used to access SABnzbd.

          - 127.0.0.1 or [::1] or localhost (default) = Access from this computer only
          - empty = Finds and listens on your local (IPv4) IP address. Used for accessing from other computers. localhost will not work anymore so update your bookmarks.
          - 0.0.0.0 = Listens on multiple interfaces (both local IP and localhost).
          - :: = Listen on both IPv4 and IPv6 addresses for local and network access.

          More information can be found in the [SABnzbd docs](https://sabnzbd.org/wiki/configuration/4.5/general)
        '';
      };

      port = mkOption {
        type = types.port;
        default = 8080;
        description = ''
          The internal webserver needs a port to listen on.
          The default port is 8080.
          Try another one if this address is already occupied by another program on your computer.

          More information can be found in the [SABnzbd docs](https://sabnzbd.org/wiki/configuration/4.5/general)
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Open ports in the firewall for the sabnzbd web interface
        '';
      };
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    users.users = mkIf (cfg.user == "sabnzbd") {
      sabnzbd = {
        uid = config.ids.uids.sabnzbd;
        group = cfg.group;
        description = "sabnzbd user";
      };
    };

    users.groups = mkIf (cfg.group == "sabnzbd") {
      sabnzbd.gid = config.ids.gids.sabnzbd;
    };

    systemd.services.sabnzbd = {
      description = "sabnzbd server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "forking";
        GuessMainPID = "no";
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "sabnzbd";
        ExecStart = "${lib.getBin cfg.package}/bin/sabnzbd -d -s${cfg.host}:${cfg.port} -f ${cfg.configFile}";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.port];
    };
  };
}
