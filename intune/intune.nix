{ config, lib, pkgs, stdenv
, dpkg
, glib
, glibc
, zlib
, libsoup
, gnome3
, openssl
, sqlite
, webkitgtk
, curlMinimal
, xorg
, libsecret
, libuuid
, lsb-release
, getconf
, libpthreadstubs
, ... }:
let

  # https://gitlab.com/zanc/overlays/-/blob/master/edge/browser.nix

  # whole fucking file nicked from https://unix.stackexchange.com/questions/520675/making-a-simple-deb-package-nixos-compatible-mathematicas-wolframscript
  # Please keep the version x.y.0.z and do not update to x.y.76.z because the
  # source of the latter disappears much faster.
  version = "0.2202.1";

  src = builtins.fetchurl {
      #url = http://packages.microsoft.com/ubuntu/20.04/prod/pool/main/i/intune-portal/intune-portal_0.2201.1~mvr5_amd64.deb;
      #sha256 = "1s4q612awf6g6dajpm2qh7dfgpcaly04n3z69dyqqx86gb61qba9";
      #name = "intune-portal_0.2201.1.mvr5_amd64.deb";
      url = https://packages.microsoft.com/ubuntu/20.04/prod/pool/main/i/intune-portal/intune-portal_1.2202.1_amd64.deb;
      sha256 = "0hbni2mzjaj6w5j3kayz9m9qhbdjy1g6rlr4xqpwldllfa886zza";
  };

    msedge = pkgs.callPackage /etc/nixos/features/msedge.nix {};
    msaldk = pkgs.callPackage /etc/nixos/features/intune/msaldk.nix {};
    libsdbus= pkgs.callPackage /etc/nixos/features/intune/libsdbus.nix {};
    msft-identity-broker = pkgs.callPackage /etc/nixos/features/intune/msft-identity-broker.nix {};

in stdenv.mkDerivation {
  name = "intune-${version}";

  system = "x86_64-linux";

  inherit src;

  nativeBuildInputs = with pkgs; [
    #autoPatchelfHook
    dpkg
  ];

  # Required at running time
  buildInputs = with pkgs; [
    #stdenv.cc.cc.lib
    glib
    glibc
    zlib
    libsoup
    pkgs.gtk3
    openssl
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
    libpthreadstubs
  ];

  unpackPhase = "true";
  dontStrip = true;

  # fix nicked from https://github.com/afrepues/nixpkgs/commit/9662d78b943ac2efbdfceb6f69f7216e282aad8f
  buildPhase = ''
    cd $TMP
    dpkg --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner
  '';

  # Extract and copy executable in $out/bin
  installPhase = ''
    mkdir -p $out
    ls $TMP
    cp -av $TMP/usr/* $TMP/lib $out/
    #cp -av $TMP/usr/* $out/
    
  '';

  meta = with lib; {
    description = "company-portal";
    homepage = https://www.microsoft.com/en-us/edge;
    license = "";
    maintainers = with lib.maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
}