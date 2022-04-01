{ config, lib, pkgs, stdenv
, dpkg
, glib
, systemd
, dbus
 }:
let
  version = "0.8.3";

  src = builtins.fetchurl {
      url = http://mirrors.kernel.org/ubuntu/pool/universe/s/sdbus-cpp/libsdbus-c++0_0.8.3-4~bpo20.04.1_amd64.deb;
      sha256 = "038pd8532qi8k3siv6dbrp7bjfwrrfhbx8w893if6zlwwyl6q3vl";
      name = "libsdbus-c++-dev.amd64.deb";
  };


in stdenv.mkDerivation {
  name = "libsdbus-${version}";
  pname = "libsdbus";
  system = "x86_64-linux";

  inherit src;

  nativeBuildInputs = with pkgs; [ dpkg  ];
  buildInputs = with pkgs; [
    glib
    systemd
    dbus
  ];

  unpackPhase = "true";

  buildPhase = ''
    cd $TMP
    dpkg -x $src .
  '';

  installPhase = ''
    mkdir -p $out/lib
    ls $TMP
    cp -av $TMP/usr/lib/x86_64-linux-gnu/* $out/lib/
  '';

  meta = with lib; {
    description = "libsdbus";
    homepage = https://www.microsoft.com/en-us/edge;
    license = "";
    maintainers = with lib.maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
}