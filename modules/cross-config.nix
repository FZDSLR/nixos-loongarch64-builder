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
    rust = {
      platform = builtins.fromJSON (
        builtins.readFile "${../rust}/loongarch64_nosimd-unknown-gnu.json"
      );
      rustcTargetSpec = "${../rust}/loongarch64_nosimd-unknown-gnu.json";
      rustcTarget = "loongarch64_nosimd-unknown-gnu.json";
    };
  };
  nixpkgs.overlays = [
    (import ../overlays/default.nix)
    (rust-overlay.overlays.default)
  ];
}
