(self: super: {
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
})
