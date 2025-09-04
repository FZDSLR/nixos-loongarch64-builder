{
  lib,
  pkgs,
  rust-overlay,
  ...
}:
{
  nixpkgs.crossSystem = lib.recursiveUpdate lib.systems.examples.loongarch64-linux-embedded {
    linux-kernel = {
      name = "loong64";
      target = "uImage";
    };
  };
  nixpkgs.overlays = [
    (import ../overlays/default.nix)
    (rust-overlay.overlays.default)
  ];
}
