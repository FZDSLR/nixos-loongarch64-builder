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

      openblas = super.openblas.overrideAttrs (old: {
        makeFlags = super.lib.lists.remove "BINARY=64" old.makeFlags;
      });

    })
  ];
}
