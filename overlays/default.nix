{
  config,
  pkgs,
  lib,
  ...
}:

{
  nixpkgs.overlays = [
    (self: super: {
      libressl = super.libressl_3_6;
    })
  ];
}
