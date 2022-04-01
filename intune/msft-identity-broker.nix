{ config, lib, pkgs, stdenv, dpkg
, gcc-unwrapped
, glib
, glibc
, systemd
, openssl
, jdk11_headless
, coreutils
, gsettings-desktop-schemas 
, ... }:
let

  # https://gitlab.com/zanc/overlays/-/blob/master/edge/browser.nix

  # whole fucking file nicked from https:    basename//unix.stackexchange.com/questions/520675/making-a-simple-deb-package-nixos-compatible-mathematicas-wolframscript
  # Please keep the version x.y.0.z and do not update to x.y.76.z because the
  # source of the latter disappears much faster.
  version = "1.0.6";

  src = builtins.fetchurl {
      url = http://packages.microsoft.com/ubuntu/20.04/prod/pool/main/m/msft-identity-broker/msft-identity-broker_1.0.6_amd64.deb;
      sha256 = "1frbqsvsz74w1sms2sdbn402b2aabp4v354g4qs2nl0agcnvw8sm";
  };

  #libsdbus = pkgs.callPackage /etc/nixos/features/intune/libsdbus.nix {};
  #msaldk = pkgs.callPackage /etc/nixos/features/intune/msaldk.nix {};


in stdenv.mkDerivation {
  name = "msft-identity-broker-${version}";
  pname = "msft-identity-broker";
  system = "x86_64-linux";

  inherit src;

  nativeBuildInputs = with pkgs; [jdk dpkg makeWrapper autoPatchelfHook];

  # Required at running time
  buildInputs = with pkgs; [
    dpkg
    glib
    glibc
    systemd
    openssl
    jdk11_headless
    #libsdbus
    #msaldk
    coreutils
    gsettings-desktop-schemas
    gtk3
  ];

  unpackPhase = "true";

  buildPhase = ''
    cd $TMP
    dpkg -x $src .
  '';

  # Extract and copy executable in $out/bin
  installPhase = ''
    mkdir -p $out

    cp -av $TMP/usr/* $out/
    cp -av $TMP/opt $out/
    #cp -av ${coreutils}/bin/which $out/opt/msft/identitybroker/bin/
    
    # fix the dbus and systemd files to be in their propr place.
    #sed -i "s|/opt/msft/identitybroker/|$out/opt/msft/identitybroker/|g" $out/lib/systemd/system/msft-identity-device-broker.service
    #sed -i "s|/opt/msft/identitybroker/|$out/opt/msft/identitybroker/|g" $out/lib/systemd/user/msft-identity-broker.service
    #sed -i "s|/opt/msft/identitybroker/|$out/opt/msft/identitybroker/|g" $out/share/dbus-1/system-services/com.microsoft.identity.devicebroker1.service
    #sed -i "s|/opt/msft/identitybroker/|$out/opt/msft/identitybroker/|g" $out/share/dbus-1/services/com.microsoft.identity.broker1.service
    #echo User=root >> $out/share/dbus-1/system-services/com.microsoft.identity.devicebroker1.service
    #rm $out/share/dbus-1/services/com.microsoft.identity.broker1.service $out/lib/systemd/system/msft-identity-device-broker.service $out/lib/systemd/user/msft-identity-broker.service
    #rm $out/share/dbus-1/system-services/com.microsoft.identity.devicebroker1.service

    #wrapProgram $out/opt/msft/identitybroker/bin/msft-identity-device-broker \
    #--prefix PATH : ${coreutils}/bin \
    #--set MSFT_IDENTITY_BROKER_OPTS "-verbose" \
    #--set JAVA_HOME ${jdk11_headless.home} \
    #--prefix LD_LIBRARY_PATH : ${pkgs.gtk3}/lib 

    #wrapProgram $out/opt/msft/identitybroker/bin/msft-identity-broker \
    #--prefix PATH : ${coreutils}/bin \
    #--set MSFT_IDENTITY_BROKER_OPTS "-verbose" \
    #--set JAVA_HOME ${jdk11_headless.home} \
    #--prefix LD_LIBRARY_PATH : ${pkgs.gtk3}/lib 

    #--set DBUS_SESSION_BUS_ADDRESS "unix:path=$dbus_socket_dir/session" 
  '';

  #     --prefix XDG_DATA_DIRS : ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name} \


  meta = with lib; {
    description = "msft-identity-broker";
    homepage = https://www.microsoft.com/en-us/edge;
    license = "";
    maintainers = with lib.maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
}
