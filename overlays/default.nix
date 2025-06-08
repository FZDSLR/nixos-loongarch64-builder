(
  self: super:

  let
    isCross = super.stdenv.buildPlatform != super.stdenv.hostPlatform;
    isCrossTarget = super.stdenv.buildPlatform != super.stdenv.targetPlatform;
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

    ubootLs99PiTF =
      (super.buildUBoot {
        defconfig = "loongson_2k300_99pi_tf_defconfig";
        extraMeta.platforms = [ "loongarch64-linux" ];
        filesToInstall = [ "u-boot-with-spl.bin" ];
        src = super.fetchgit {
          url = "https://gitee.com/open-loongarch/u-boot.git";
          rev = "96038f5a0c757fab5606ef916055c61f741aca07";
          sha256 = "sha256-OpPOCVR5eel0U3wenBNaRmaMEv7WYbBiWZfexEfo+Dw=";
        };
        version = "2024.04";
        extraConfig = ''
          CONFIG_CMD_SYSBOOT=y
        '';
      }).overrideAttrs
        ({ patches = [ ./initrd-support.patch ]; });

    rustPlatform_1_83 = super.makeRustPlatform {
      cargo = self.buildPackages.rust-bin.stable."1.83.0".minimal;
      rustc = self.buildPackages.rust-bin.stable."1.83.0".minimal;
    };

    rustPlatform = if isCross then self.rustPlatform_1_83 else super.rustPlatform;

    cargo = if isCrossTarget then self.buildPackages.rust-bin.stable."1.83.0".minimal else super.cargo;
    rustc = if isCrossTarget then self.buildPackages.rust-bin.stable."1.83.0".minimal else super.rustc;

  }

)
