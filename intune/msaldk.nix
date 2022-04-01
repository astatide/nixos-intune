{ config, lib, pkgs, stdenv
, dpkg
, gcc-unwrapped
, glib
 }:
let 
  version = "1.0.0";

  src = builtins.fetchurl {
      url = http://packages.microsoft.com/ubuntu/20.04/prod/pool/main/m/msalsdk-dbusclient/msalsdk-dbusclient_1.0.0_amd64.deb;
      sha256 = "0dhbmwrkqg3swd3y8f6r5xrnvrzc1vkpc10sdw4z6fwx0cbqsn3q";
  };

  libsdbus = pkgs.callPackage /etc/nixos/features/intune/libsdbus.nix {};

in stdenv.mkDerivation {
  name = "msaldk-${version}";
  pname = "msalsdk-dbusclient";
  system = "x86_64-linux";

  inherit src;

  nativeBuildInputs = with pkgs; [ dpkg ];
  buildInputs = with pkgs; [
    glib
    libsdbus
  ];

  unpackPhase = "true";

  buildPhase = ''
    cd $TMP
    dpkg -x $src .
  '';

  # Extract and copy executable in $out/bin
  installPhase = ''
    mkdir -p $out
    ls $TMP
    cp -av $TMP/usr/* $out/    
  '';

  meta = with lib; {
    description = "msaldk";
    homepage = https://www.microsoft.com/en-us/edge;
    license = "";
    maintainers = with lib.maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
}