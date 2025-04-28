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
    (podman.override {
      extraRuntimes = [ pkgs.crun ];
    })
    (python3.withPackages (
      ps: with ps; [
        requests
        flask
        spidev
        numpy
        opencv4
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
