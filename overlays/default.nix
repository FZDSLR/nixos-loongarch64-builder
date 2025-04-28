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

      webrtc-audio-processing = super.webrtc-audio-processing.overrideAttrs (oldAttrs: {
        meta.platforms = oldAttrs.meta.platforms ++ [ "loongarch64-linux" ];
      });
      webrtc-audio-processing_1 = super.webrtc-audio-processing_1.overrideAttrs (oldAttrs: {
        meta.platforms = oldAttrs.meta.platforms ++ [ "loongarch64-linux" ];
      });

      openblas = super.openblas.overrideAttrs (old: {
        makeFlags = super.lib.lists.remove "BINARY=64" old.makeFlags;
      });

    })
  ];
}
