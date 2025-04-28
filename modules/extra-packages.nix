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
  ];
}
