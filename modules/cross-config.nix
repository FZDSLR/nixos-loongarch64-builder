{ lib, pkgs, ... }:
{
  nixpkgs.crossSystem = {
    system = "loongarch64-linux";
    config = "loongarch64-unknown-linux-gnu";
    gcc.arch = "loongarch64";
    linux-kernel = {
      name = "loong64";
      target = "uImage";
    };
    rustc.config = "loongarch64-unknown-linux-gnu";
    rustc.platform = {
      arch = "loongarch64";
      os = "linux";
      target-family = [ "unix" ];
      vendor = "unknown";
      features= "+f,+d";
    };
  };
  nixpkgs.overlays = [(import ../overlays/default.nix)];
}
