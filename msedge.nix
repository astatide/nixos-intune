{ config, lib, pkgs, stdenv, dpkg, glibc, gcc-unwrapped, xorg, glib
, nss
, nspr
, atk
, at_spi2_atk
, cups
, file
, dbus_libs
, expat
, libdrm
, libxkbcommon
, gnome3
, gnome2
, cairo
, gdk-pixbuf
, mesa
, alsaLib
, at_spi2_core
, systemd
, nssmdns
, autoPatchelfHook
, libsecret
, wayland
, vulkan-tools
, vulkan-headers
, vulkan-loader
, vaapiVdpau
, libvdpau
, libvdpau-va-gl
, libva-utils
, pipewire
, gsettings-desktop-schemas
, xdg-utils
, pulseaudioFull
, xdg-desktop-portal-gtk
, libglvnd
, coreutils
, libuuid, ... }:
let

  # https://gitlab.com/zanc/overlays/-/blob/master/edge/browser.nix

  # whole fucking file nicked from https://unix.stackexchange.com/questions/520675/making-a-simple-deb-package-nixos-compatible-mathematicas-wolframscript
  #version = "99.0.1131";
  #version = "99.0.1150";
  version = "100.0.1163";

  src = builtins.fetchurl {
      #url = https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-dev/microsoft-edge-dev_99.0.1131.3-1_amd64.deb;
      #url = https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-dev/microsoft-edge-dev_99.0.1141.0-1_amd64.deb;
      #url = https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-dev/microsoft-edge-dev_99.0.1150.2-1_amd64.deb;
      #sha256 = "sha256:1rl9krdl9i5l46n2b1j6m3m7jd9df7b7rnb2lp846c71rx4b16x8";
      #url = https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-dev/microsoft-edge-dev_99.0.1150.7-1_amd64.deb;
      #sha256 = "1aqbswxb1d2q0gyzrvr50vj37kymligyd7bjb5cpbia4kcf8isb6";
      #url = file:///home/astatide/Downloads/microsoft-edge-dev_99.0.1151.0-1_amd64.deb;
      #sha256 = "sha256:0n3vf5nvb4rmrh6212g70vsl45pqf98b14c0y3zpyk4w0dajcypx";
      url = https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-dev/microsoft-edge-dev_100.0.1163.1-1_amd64.deb;
      sha256 = "153faqxyw5f5b6cqnvd71dl7941znkzci8dwbcgaxway0b6882jq";
  };


  msaldk = pkgs.callPackage /etc/nixos/features/intune/msaldk.nix {};
  libsdbus = pkgs.callPackage /etc/nixos/features/intune/libsdbus.nix {};
  msft-identity-broker = pkgs.callPackage /etc/nixos/features/intune/msft-identity-broker.nix {};
  intune = pkgs.callPackage /etc/nixos/features/intune/intune.nix {};

  # wow this is super not how this sort of shit is done but like whatever
  enableWayland = true;

  # WebRTCPipeWireCapturer

  waylandFlags = ''
  --add-flags "--enable-features=msEdgeSyncESR,msEnableAADSignInOnLinux,UseOzonePlatform,VaapiVideoDecoder,VaapiVideoEncoder --disable-gpu-driver-bug-workarounds --ozone-platform=wayland --ignore-gpu-blacklist --enable-gpu-rasterization --enable-oop-rasterization --enable-accelerated-video-decode --enable-accelerated-video-encode --use-gl=egl"
  '';
  regularFlags = ''
  --add-flags "--enable-features=msEdgeSyncESR,msEnableAADSignInOnLinux,VaapiVideoDecoder,VaapiVideoEncoder,WebRTCPipeWireCapturer --disable-gpu-driver-bug-workarounds --enable-accelerated-video-decode --enable-accelerated-video-encode --use-gl=desktop --ignore-gpu-blacklist --enable-gpu-rasterization --enable-oop-rasterization"
  '';

  programFlags = if enableWayland then waylandFlags else regularFlags;

in stdenv.mkDerivation {
  name = "msedge-dev-${version}";

  system = "x86_64-linux";

  inherit src;

  nativeBuildInputs = [ autoPatchelfHook ];
  # Required at running time
  buildInputs = with pkgs; [
    xorg.libxshmfence
    dpkg
    glibc glib nss nspr atk at_spi2_atk xorg.libX11
    xorg.libxcb cups.lib dbus_libs.lib expat libdrm
    xorg.libXcomposite xorg.libXdamage xorg.libXext
    xorg.libXfixes xorg.libXrandr libxkbcommon
    pkgs.gtk3 gnome2.pango cairo gdk-pixbuf pkgs.gtk4
    alsaLib at_spi2_core xorg.libxshmfence systemd
    libsecret makeWrapper wayland libatomic_ops clang
    gcc-unwrapped vulkan-tools pkgs.linuxKernel.packages.linux_xanmod.nvidia_x11
    libsdbus
    libvdpau
    libvdpau-va-gl
    vaapiVdpau
    libva-utils
    vulkan-headers
    vulkan-loader
    pipewire
    gsettings-desktop-schemas
    xdg-utils
    pulseaudioFull
    msft-identity-broker
    xdg-desktop-portal-gtk
    zsh
    mesa
    libglvnd
    msaldk
  ];

  unpackPhase = "true";
  #dontPatch = true;
  #dontConfigure = true;
  #dontPatchELF = true;


  # fix nicked from https://github.com/afrepues/nixpkgs/commit/9662d78b943ac2efbdfceb6f69f7216e282aad8f
  buildPhase = ''
    cd $TMP
    dpkg --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner
  '';

  # Extract and copy executable in $out/bin
  installPhase = ''
    mkdir -p $out
    cp -av $TMP/opt $out/
    cp -av $TMP/usr/* $out/
    unlink $out/bin/microsoft-edge-dev
    ln -sv $out/opt/microsoft/msedge-dev/microsoft-edge-dev $out/bin/microsoft-edge-dev
    ln -sv $out/opt/microsoft/msedge-dev/msedge $out/bin/msedge

    # oneauth? Looks like we use this but don't necessarily find it in a sane location.
    cp -vr ${msaldk}/lib/libmsal_dbus_client.so $out/opt/microsoft/msedge-dev/

    # sets up a wrapper to add the necessary arguments.
    wrapProgram $out/opt/microsoft/msedge-dev/microsoft-edge-dev \
    --prefix LD_LIBRARY_PATH : ${vulkan-loader}/lib \
    --prefix LD_LIBRARY_PATH : ${wayland}/lib \
    --prefix LD_LIBRARY_PATH : ${pipewire}/lib \
    --prefix LD_LIBRARY_PATH : ${pipewire.lib}/lib \
    --prefix LD_LIBRARY_PATH : ${pipewire.pulse}/lib \
    --prefix LD_LIBRARY_PATH : ${pulseaudioFull}/lib \
    --prefix LD_LIBRARY_PATH : ${libglvnd}/lib \
    --prefix LD_LIBRARY_PATH : ${msaldk}}/lib \
    --prefix LD_LIBRARY_PATH : ${systemd}/lib \
    --prefix LD_LIBRARY_PATH : ${pkgs.dbus_libs}/lib \
    --prefix LD_LIBRARY_PATH : ${pkgs.gtk3}/lib \
    --prefix LD_LIBRARY_PATH : ${libsdbus}/lib \
    ${programFlags}

    rm -rf $out/share/doc
    rm -rf $out/opt/microsoft/msedge-dev/cron

    substituteInPlace $out/share/applications/microsoft-edge-dev.desktop \
      --replace /usr/bin/microsoft-edge-dev $out/bin/microsoft-edge-dev \
      --replace "Icon=microsoft-edge-dev" "Icon=$out/opt/microsoft/msedge-dev/product_logo_128_dev.png"

    substituteInPlace $out/share/gnome-control-center/default-apps/microsoft-edge-dev.xml \
      --replace /opt/microsoft/msedge-dev $out/opt/microsoft/msedge-dev

    substituteInPlace $out/share/menu/microsoft-edge-dev.menu \
      --replace /opt/microsoft/msedge-dev $out/opt/microsoft/msedge-dev

    substituteInPlace $out/opt/microsoft/msedge-dev/xdg-mime \
      --replace "''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" "''${XDG_DATA_DIRS:-/run/current-system/sw/share}" \
      --replace "xdg_system_dirs=/usr/local/share/:/usr/share/" "xdg_system_dirs=/run/current-system/sw/share/" \
      --replace /usr/bin/file ${file}/bin/file

    substituteInPlace $out/opt/microsoft/msedge-dev/default-app-block \
      --replace /opt/microsoft/msedge-dev $out/opt/microsoft/msedge-dev

    substituteInPlace $out/opt/microsoft/msedge-dev/xdg-settings \
      --replace "''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" "''${XDG_DATA_DIRS:-/run/current-system/sw/share}" \
      --replace "''${XDG_CONFIG_DIRS:-/etc/xdg}" "''${XDG_CONFIG_DIRS:-/run/current-system/sw/etc/xdg}"

  '';

  meta = with lib; {
    description = "msedge-dev";
    homepage = https://www.microsoft.com/en-us/edge;
    license = "";
    maintainers = with lib.maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
}
