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
          # Since https://github.com/NixOS/nixpkgs/commit/ebf43d4c4a50beba220015cd70239a56f7fa6360
          filesToInstall = [
            "tools/dumpimage"
            "tools/fdtgrep"
            "tools/kwboot"
            "tools/mkenvimage"
            "tools/mkimage"
            "tools/env/fw_printenv"
          ];
          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            cp ${super.lib.concatStringsSep " " (finalAttrs.filesToInstall)} $out/bin

            mkdir -p "$out/bin/nix-support"
            ${super.lib.concatMapStrings (file: ''
              echo "file binary-dist $out/bin/${builtins.baseNameOf file}" >> "$out/bin/nix-support/hydra-build-products"
            '') (finalAttrs.filesToInstall)}

            runHook postInstall
          '';
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

    linuxPackages_aosc_2k300 = super.linuxPackagesFor (
      super.callPackage ../packages/linux-aosc.nix { }
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

    haskellPackages-la = super.haskellPackages.override {
      ghc =
        if isCrossTarget then
          super.haskellPackages.ghc.override {
            libffi = null;
            useLLVM = false;
            enableUnregisterised = true;
          }
        else
          super.haskellPackages.ghc;
    };

    fish = super.fish.overrideAttrs (oldAttrs: {
      cmakeFlags =
        let
          # 过滤掉所有形式的 Rust_CARGO_TARGET 标志
          filteredFlags = builtins.filter (
            flag:
            if builtins.isString flag then
              let
                # 检查是否以 -DRust_CARGO_TARGET 开头
                isRustFlag = builtins.substring 0 19 flag == "-DRust_CARGO_TARGET";
              in
              !isRustFlag
            else
              true
          ) oldAttrs.cmakeFlags;

          # 生成新的 Rust_CARGO_TARGET 标志
          newRustFlag = (
            super.lib.cmakeFeature "Rust_CARGO_TARGET" super.stdenv.hostPlatform.rust.rustcTargetSpec
          );
        in
        filteredFlags ++ [ newRustFlag ];
      patches = (oldAttrs.patches or [ ]) ++ [
        ./fish-custom-target-fix.patch
      ];
    });

    librsvg = super.librsvg.overrideAttrs (oldAttrs: {
      mesonFlags =
        let
          filteredFlags = builtins.filter (
            flag:
            if builtins.isString flag then
              let
                isRustFlag = builtins.substring 0 9 flag == "-Dtriplet";
              in
              !isRustFlag
            else
              true
          ) oldAttrs.mesonFlags;

          newRustFlag = ("-Dtriplet=${super.stdenv.hostPlatform.rust.rustcTargetSpec}");
        in
        filteredFlags ++ [ newRustFlag ];
      patches = (oldAttrs.patches or [ ]) ++ [
        ./librsvg_fix_target_dir.patch
      ];
    });

    cargo-c =
      if isCrossTarget then
        super.cargo-c.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [
            ./cargo-c-fix-json-path.patch
          ];
        })
      else
        super.cargo-c;

    libimagequant =
      if isCross then
        super.libimagequant.overrideAttrs (oldAttrs: {
          postBuild = ''
            pushd imagequant-sys
            ${super.buildPackages.rust.envVars.setEnv} cargo cbuild --release --frozen --prefix=${placeholder "out"} --target ${super.stdenv.hostPlatform.rust.rustcTargetSpec}
            popd
          '';
          postInstall = ''
            pushd imagequant-sys
            ${super.buildPackages.rust.envVars.setEnv} cargo cinstall --release --frozen --prefix=${placeholder "out"} --target ${super.stdenv.hostPlatform.rust.rustcTargetSpec}
            popd
          '';
        })
      else
        super.libimagequant;

    brotli =
      if isCross then
        super.brotli.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [
            (super.fetchurl {
              url = "https://github.com/google/brotli/commit/e230f474b87134e8c6c85b630084c612057f253e.patch";
              hash = "sha256-QERl8RHJz7tFr++hZIYwdj1/ogPpjArC+ia8S/bWxKk=";
            })
          ];
        })
      else
        super.brotli;

    perlPackages = super.perlPackages // {
      JSON = super.perlPackages.JSON.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ (
          if isCross then [ ./JSON-41-disable-b.patch ] else [ ]
        );
      });
    };
  }
)
