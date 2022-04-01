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
    
  '';

  meta = with lib; {
    description = "msft-identity-broker";
    homepage = https://www.microsoft.com/en-us/edge;
    license = "";
    maintainers = with lib.maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
}
