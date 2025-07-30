(
  self: super:

  let
    isCross = super.stdenv.buildPlatform != super.stdenv.hostPlatform;
    isCrossTarget = super.stdenv.buildPlatform != super.stdenv.targetPlatform;
    libressl-loongarch64Conf = super.fetchurl {
      url = "https://raw.githubusercontent.com/libressl-portable/portable/v4.1.0/include/arch/loongarch64/opensslconf.h";
      sha256 = "02l6h1qqrbzmdk10ybzs0m8v9ps72cg32hm737x5rjwlrkk71izb";
    };
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

    linuxPackages_6_12_2k300 = super.linuxPackagesFor (
      super.callPackage ../packages/linux-6.12-2k300.nix { }
    );

    linuxPackages_6_12_2k300_rt = super.linuxPackagesFor (
      super.callPackage ../packages/linux-6.12-2k300.nix {
        configfile = ../packages/loongson_2k300_rt_config;
      }
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

    podman = super.podman.override {
      extraRuntimes = [ ];
    };

    runc = super.runc.overrideAttrs (
      finalAttrs: previousAttrs: {
        version = "1.3.0";
        src = super.fetchFromGitHub {
          owner = "opencontainers";
          repo = "runc";
          rev = "v${finalAttrs.version}";
          hash = "sha256-oXoDio3l23Z6UyAhb9oDMo1O4TLBbFyLh9sRWXnfLVY=";
        };
        patches = previousAttrs.patches or [ ] ++ [
          (super.fetchurl {
            url = "https://gitlab.alpinelinux.org/alpine/aports/-/raw/82e8ff7e79e388c9363b0c0781c04c944a4caacd/community/runc/add-seccomp-for-loongarch64.patch";
            sha256 = "17krbjkw8lzf9x3h10zw5bpgcgs4ibwadakabrl98nj4vnp5qfqb";
          })
        ];
      }
    );

    rustPlatform_1_83 = super.makeRustPlatform {
      cargo = self.buildPackages.rust-bin.stable."1.83.0".minimal;
      rustc = self.buildPackages.rust-bin.stable."1.83.0".minimal;
    };

    rustPlatform = if isCross then self.rustPlatform_1_83 else super.rustPlatform;

    cargo =
      if isCrossTarget then
        self.buildPackages.rust-bin.stable."1.83.0".minimal.override {
          targets = [ "loongarch64-unknown-linux-gnu" ];
        }
      else
        super.cargo;
    rustc =
      if isCrossTarget then
        self.buildPackages.rust-bin.stable."1.83.0".minimal.override {
          targets = [ "loongarch64-unknown-linux-gnu" ];
        }
      else
        super.rustc;

    cargo-auditable-cargo-wrapper =
      if isCrossTarget then
        super.cargo-auditable-cargo-wrapper.override {
          cargo = self.buildPackages.rust-bin.stable."1.83.0".minimal.override {
            targets = [ "loongarch64-unknown-linux-gnu" ];
          };
        }
      else
        super.cargo-auditable-cargo-wrapper;

    haskellPackages-la = super.haskellPackages.override (old: {
      ghc =
        if isCrossTarget then
          (super.haskellPackages.ghc.override {
            libffi = null;
            useLLVM = false;
            enableUnregisterised = true;
          }).overrideAttrs
            (
              finalAttrs: previousAttrs: {
                patches = previousAttrs.patches or [ ] ++ [
                 (super.fetchurl {
                   url = "https://raw.githubusercontent.com/loongson-community/nixpkgs/17acac4db46d81ab345570d1e629bc14c9e1e8d7/pkgs/development/compilers/ghc/0002-configure-Bump-max-LLVM-version-to-19.patch";
                   sha256 = "00gdni8dljjd2b8a7g0mjmacjwr922gzmkarhbwyf6nzvd0177z5";
                 })
                ];
              }
            )
        else
          super.haskellPackages.ghc;
      overrides = self.lib.composeExtensions (old.overrides or (_: _: { })) (
        hself: hsuper: {
          iserv = super.haskell.lib.justStaticExecutables (hself.callPackage ../packages/iserv.nix { });
          generics-sop = super.haskell.lib.appendBuildFlags hsuper.generics-sop [
            "--ghc-options=\"-fexternal-interpreter -pgmi ${self.qemu-iserv-wrapper}/bin/qemu-iserv-wrapper\""
          ];
        }
      );
    });

    qemu-iserv-wrapper = super.pkgsBuildHost.writeShellScriptBin "qemu-iserv-wrapper" ''
      set -euo pipefail
      exec ${super.pkgsBuildHost.qemu-user}/bin/qemu-loongarch64 "${super.pkgsHostTarget.haskellPackages-la.iserv}/bin/iserv" "$@"
    '';

    wrappedGHC =
      self.pkgsBuildHost.runCommand "ghc-wrapped"
        {
          nativeBuildInputs = [ super.pkgsBuildHost.makeWrapper ];
          passthru = self.haskellPackages-la.ghc.passthru or { } // {
            version = self.haskellPackages-la.ghc.version;
            isGhcjs = false;
            enableShared = self.haskellPackages.ghc.enableShared or true;
          };
        }
        ''
          mkdir -p $out/bin

          makeWrapper ${self.haskellPackages-la.ghc}/bin/loongarch64-unknown-linux-gnu-ghc $out/bin/loongarch64-unknown-linux-gnu-ghc \
            --add-flags "-fexternal-interpreter" \
            --add-flags "-pgmi ${self.qemu-iserv-wrapper}/bin/qemu-iserv-wrapper" \

          for tool in ${self.haskellPackages-la.ghc}/bin/*; do
            if [[ $(basename "$tool") != "loongarch64-unknown-linux-gnu-ghc" ]]; then
              ln -s "$tool" $out/bin/
            fi
          done

          ln -s ${self.haskellPackages-la.ghc}/lib $out/lib
          ln -s ${self.haskellPackages-la.ghc}/share $out/share
          ln -s ${self.haskellPackages-la.ghc}/include $out/include

          if [ -e ${self.haskellPackages-la.ghc}/package.conf.d ]; then
            ln -s ${self.haskellPackages-la.ghc}/package.conf.d $out/package.conf.d
          fi
        '';

    haskellPackages-la-wrapped = self.haskellPackages-la.override (old: {
      overrides = self.lib.composeExtensions (old.overrides or (_: _: { })) (
        hself: hsuper: {
          ghc = self.wrappedGHC;
        }
      );
    });

  }
)
