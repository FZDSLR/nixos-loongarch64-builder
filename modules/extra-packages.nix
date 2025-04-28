{
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    file
    tree
    gnutar
    p7zip
    cowsay
    curl
    vim
    git
    nginx
    fish
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
    fzf

    (fastfetch.override {
      rpmSupport = false;
      vulkanSupport = false;
      waylandSupport = false;
      x11Support = false;
    })

    (podman.override {
      extraRuntimes = [ pkgs.crun ];
    })

    (python3.withPackages (
      ps: with ps; [
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
      ]
    ))
  ];
}
