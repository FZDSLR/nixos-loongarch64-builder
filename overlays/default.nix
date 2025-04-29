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

      x264 = super.x264.overrideAttrs (old: {
        preConfigure =
          (old.preConfigure or "")
          + lib.optionalString super.stdenv.hostPlatform.isLoongArch64 ''
            export AS=$CC
          '';
      });
    })
  ];
}
