{ config, pkgs, lib, modulesPath, ...}:
let

  msedge = pkgs.callPackage /etc/nixos/features/msedge.nix {};
  msaldk = pkgs.callPackage /etc/nixos/features/intune/msaldk.nix {};
  libsdbus = pkgs.callPackage /etc/nixos/features/intune/libsdbus.nix {};
  msft-identity-broker = pkgs.callPackage /etc/nixos/features/intune/msft-identity-broker.nix {};
  intune = pkgs.callPackage /etc/nixos/features/intune/intune.nix {};

  targetPkgs = pkgs: with pkgs; [
    msaldk
    msedge
    libsdbus
    msft-identity-broker
    intune
    glib
    glibc
    systemd
    openssl
    jdk11
    coreutils
    which
    gsettings-desktop-schemas 
    lsb-release
    dbus
    zlib
    libsoup
    pkgs.gtk3
    sqlite
    webkitgtk
    curlMinimal
    msaldk
    xorg.libX11
    libsecret
    libuuid
    lsb-release
    getconf
    libsdbus
    libpwquality
    xdg-utils
    xdg-desktop-portal-gtk # wait, was it this?  Is this necessary for the broker?
    zsh
  ];

  common-password = pkgs.stdenv.mkDerivation {
    name = "common-password";
    buildCommand = ''
      set -x
      echo $common-password
      mkdir -p $out/etc/pam.d
      cp -vr $commonpassword $out/etc/pam.d/common-password
    '';
    commonpassword = pkgs.writeTextFile {
      name = "common-password-file";
      text = ''
        password  requisite pam_pwquality.so retry=3 minlen=12 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
      '';
    };
  };

  env_vars = ''
    export JAVA_HOME=${pkgs.jdk11.home}
    export PATH=${pkgs.coreutils}/bin:${pkgs.which}/bin:$PATH
    export GSETTINGS_SCHEMA_DIR=${pkgs.glib.getSchemaPath pkgs.gtk3}
    export MSFT_IDENTITY_BROKER_OPTS="-verbose"
  '';

  msft-fhs = pkgs.buildFHSUserEnv {
    targetPkgs = targetPkgs;
    name = "msft-identity-device-broker"; # Name used to start this UserEnv
    runScript = "/opt/msft/identitybroker/bin/msft-identity-device-broker";
    profile = env_vars;
  };

  msft-user-fhs = pkgs.buildFHSUserEnv {
    targetPkgs = targetPkgs;
    name = "msft-identity-broker"; # Name used to start this UserEnv
    runScript = "/opt/msft/identitybroker/bin/msft-identity-broker";
    profile = env_vars;
  };

  intune-agent-fhs = pkgs.buildFHSUserEnv {
    targetPkgs = targetPkgs;
    name = "intune-agent"; # Name used to start this UserEnv
    runScript = "/usr/bin/intune-agent";
    profile = env_vars;
  };

  intune-agent-debug-fhs = pkgs.buildFHSUserEnv {
    targetPkgs = targetPkgs;
    name = "intune-agent-debug"; # Name used to start this UserEnv
    runScript = "zsh";
    profile = env_vars;
  };

  intune-portal-fhs = pkgs.buildFHSUserEnv {
    targetPkgs = targetPkgs;
    name = "intune-portal"; # Name used to start this UserEnv
    runScript = "/usr/bin/intune-portal";
    profile = env_vars;
  };

  intune-portal-debug-fhs = pkgs.buildFHSUserEnv {
    targetPkgs = targetPkgs;
    name = "intune-portal-debug"; # Name used to start this UserEnv
    runScript = "zsh";
    profile = env_vars;
  };
  
  intunePortalDesktopItem = pkgs.makeDesktopItem {
    name = "company-portal";
    desktopName = "Company Portal";
    exec = "${intune-portal-fhs}/bin/intune-portal";
    terminal = "false";
    icon = "intune";
  };

  intuneAgentDesktopItem = pkgs.makeDesktopItem {
    name = "intune-agent";
    desktopName = "Intune Agent";
    exec = "${intune-agent-fhs}/bin/intune-agent";
    terminal = "false";
    icon = "intune";
  };

in
{
  users.users.msftbroker = {
    isSystemUser = true;
    uid = 998;
    group = "msftbroker";
    extraGroups = [ "messagebus" ];
  };
  users.groups.msftbroker = {
    gid = 998;
  };

  security.pam.services.common-password.text = ''
    password  requisite   pam_pwquality.so  retry=3 minlen=14 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
  '';

  systemd.services.msft-identity-device-broker = {
    enable = true;
    description = "Microsoft Identity Device Broker Service";
    serviceConfig = {
      ExecStart = "${msft-fhs}/bin/msft-identity-device-broker";
      User="msftbroker";
      Group="msftbroker";
      Type = "dbus";
      BusName="com.microsoft.identity.devicebroker1";

      RuntimeDirectory="msft-identity-device-broker";
      StateDirectory="msft-identity-device-broker";
      LogsDirectory="msft-identity-device-broker";

      RuntimeDirectoryMode="700";
      StateDirectoryMode="700";
      LogsDirectoryMode="700";

      SuccessExitStatus="143";
      TimeoutStopSec="10";
      Restart="on-failure";
      RestartSec="5";
    };
    wantedBy = [ "multi-user.target" ];
    # ...
  };

  systemd.user.services.msft-identity-broker = {
    enable = true;
    description = "Microsoft Identity Broker Service";
    serviceConfig = {
      ExecStart = "${msft-user-fhs}/bin/msft-identity-broker";
      Type = "dbus";
      BusName="com.microsoft.identity.broker1";

      RuntimeDirectory="msft-identity-broker";
      StateDirectory="msft-identity-broker";
      LogsDirectory="msft-identity-broker";

      RuntimeDirectoryMode="700";
      StateDirectoryMode="700";
      LogsDirectoryMode="700";

      SuccessExitStatus="143";
      TimeoutStopSec="10";
      Restart="on-failure";
      RestartSec="5";
    };
    wantedBy = [ "multi-user.target" ];
    # ...
  };

  systemd.user.services.intune-agent = {
    enable = true;
    description = "Intune Agent";
    serviceConfig = {
      ExecStart = "${intune-agent-fhs}/bin/intune-agent";
      Type = "oneshot";
    };
    wantedBy = [ "multi-user.target" ];
    # ...
  };

  systemd.user.timers.intune-agent = {
    enable = true;
    description = "Intune Agent scheduler";
    timerConfig = {
      OnCalendar = "hourly";
      AccuracySec = "5m";
    };
    wantedBy = [ "timers.target" ];
    # ...
  };

  services.dbus.packages = [ msft-fhs ];
  systemd.packages = [ msft-fhs msft-user-fhs ];
  #systemd.user.packages = [msft-user-fhs];

  # Packages unique to this system.
  environment.systemPackages = with pkgs; [
    msedge
    intunePortalDesktopItem
    intuneAgentDesktopItem
    libsdbus # NEEDED for edge?
    msaldk # NEEDED for edge?
    libpwquality
    libuuid
    libsecret
    openssl
    lsb-release
    msft-fhs
    msft-user-fhs
    msft-identity-broker # how long has this been...? # I think this is where it gets the dbus conf file from.
    intune-agent-fhs
    intune-portal-fhs
    intune-portal-debug-fhs
    jdk11
    sqlite
    webkitgtk
    pam
    wayland
    coreutils # THIS MAY BE REALLY IMPORTANT FOR THE FUCKING LIBONEAUTH
    xdg-utils
    alsa-utils
    pulseaudioFull # You need this if you want sound!
    pipewire # you wanna share?  So share it.
    xdg-desktop-portal-gnome # wait, was it this?  Is this necessary for the broker?
    vulkan-tools
    vulkan-headers
    vulkan-loader
    libvdpau
    libvdpau-va-gl
    vaapiVdpau
    libva-utils
    common-password
    getconf
  ];
}
