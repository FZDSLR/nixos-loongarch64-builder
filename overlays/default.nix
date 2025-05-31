{
  lib,
  ...
}:

{
  nixpkgs.overlays = [
    (self: super: {
      ubootTools = (
        super.ubootTools.overrideAttrs (
          finalAttrs: previousAttrs: {
            version = "2024.04";
            src = super.fetchgit {
              url = "https://gitee.com/FZDSLR/uboot-la-99pi.git";
              rev = "52c5ac25f9542da6e1864fb77733d9b90726da1c";
              sha256 = "sha256-0jWwo0zUI3YjBfO2gSoWJ7W1fPx639pBnM598gQ88JI=";
            };
            patches = [ ];
          }
        )
      );

      linuxPackages_6_12_99pi_tf = super.linuxPackagesFor (
        super.callPackage ../packages/linux-6.12-99pi.nix { }
      );

      linuxPackages_6_12_99pi_wifi = super.linuxPackagesFor (
        super.callPackage ../packages/linux-6.12-99pi.nix { dtbname = "ls2k300_99pi_wifi"; }
      );

    })
  ];
}
