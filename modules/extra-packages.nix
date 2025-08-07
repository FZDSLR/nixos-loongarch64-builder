{
  lib,
  pkgs,
  ...
}:
{
  options.pkgSet.pythonPackages = lib.mkOption {
    type = with lib.types; listOf package;
    default =
      with pkgs;
      [
        python3
      ]
      ++ (with pkgs.python3Packages; [
        requests
        flask
        spidev
        numpy
        pillow
        smbus2
        python-periphery
        uptime
        distro
        psutil
      ]);
    description = "Python-related packages";
  };

  options.pkgSet.kernelPackages = lib.mkOption {
    type = with lib.types; listOf package;
    default = with pkgs; [
      linuxPackages_6_12_2k300.kernel
      linuxPackages_6_12_2k300_rt.kernel
    ];
    description = "kernel packages";
  };

  options.pkgSet.baseCliPackages = lib.mkOption {
    type = with lib.types; listOf package;
    default = with pkgs; [
      file
      tree
      gnutar
      p7zip
      unzip
      busybox
      cowsay
      hello
      curl
      wget
      vim
      git
      nginx
      nsncd
      eza
      bat
      which
      sl
      lm_sensors
      htop
      mtdutils
      i2c-tools
      openssl
      usbutils
      iw
      fish
      fzf
      ntp
      jq
      fastfetchMinimal
    ];
    description = "Useful cli packages";
  };

  options.pkgSet.otherPackages = lib.mkOption {
    type = with lib.types; listOf package;
    default = with pkgs; [
      webdav

      ffmpeg

      podman
    ];
    description = "Other packages";
  };

  config = {

  };

}
