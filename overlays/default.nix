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

  rustc = super.rustc.override (old: {
    rustc-unwrapped = old.rustc-unwrapped.overrideAttrs (oldAttrs: {
      postPatch =
        (oldAttrs.postPatch or "")
        + ''
          substituteInPlace compiler/rustc_target/src/spec/targets/loongarch64_unknown_linux_gnu.rs \
            --replace 'features: "+f,+d,+lsx".into(),' 'features: "+f,+d".into(),'
        '';
      RUSTFLAGS = (oldAttrs.RUSTFLAGS or "") + " -Cdebuginfo-level=0";
    });
  });

#   cargo-auditable = super.cargo-auditable.override(old: {
#     buildPackages = self.buildPackages;
#   });
#
#
  cargo = super.cargo.override (old:{
    rustc = self.rustc;
#     cargo-auditable = self.cargo-auditable;
  });
})
