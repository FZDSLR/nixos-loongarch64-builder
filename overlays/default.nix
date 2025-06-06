(
  self: super:

  let
    rustPackages = [
      "nsncd"
      "eza"
    ];
    updateRustPlatform = pkg: pkg.override { rustPlatform = self.rustPlatform_1_83; };
  in
  {
    ubootTools = (
      super.ubootTools.overrideAttrs (
        finalAttrs: previousAttrs: {
          version = "2024.04";
          src = super.fetchgit {
            url = "https://gitee.com/open-loongarch/u-boot.git";
            rev = "96038f5a0c757fab5606ef916055c61f741aca07";
            sha256 = "sha256-OpPOCVR5eel0U3wenBNaRmaMEv7WYbBiWZfexEfo+Dw=";
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

#     rustc = self.rust-bin.stable."1.83.0".minimal;
#     cargo = self.rust-bin.stable."1.83.0".minimal;

    rustPlatform_1_83 = super.makeRustPlatform {
      cargo = self.rust-bin.stable."1.83.0".minimal;
      rustc = self.rust-bin.stable."1.83.0".minimal;
    };

  }
  // (super.lib.genAttrs rustPackages (name: updateRustPlatform super.${name}))
)
