{
  lib,
  pkgs,
  rust-overlay,
  ...
}:
{
  nixpkgs.crossSystem = {
    system = "loongarch64-linux";
    config = "loongarch64-unknown-linux-gnu";
    gcc.arch = "loongarch64";
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
