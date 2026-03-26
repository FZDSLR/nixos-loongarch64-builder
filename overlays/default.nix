(
  self: super:

  let
    isCross = super.stdenv.buildPlatform != super.stdenv.hostPlatform;
    isCrossTarget =
      super.stdenv.buildPlatform == super.stdenv.hostPlatform
      && super.stdenv.buildPlatform != super.stdenv.targetPlatform;
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
          pythonScriptsToInstall = null;
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

    fish-indent-native = super.rustPlatform.buildRustPackage {
      pname = "fish-indent-native";
      version = super.fish.version;
      src = super.fish.src;
      cargoDeps = super.fish.cargoDeps;
      buildPhase = ''
        runHook preBuild
        cargo build --bin fish_indent --release
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        install -Dm755 target/release/fish_indent $out/bin/fish_indent
        runHook postInstall
      '';
      doCheck = false;
      strictDeps = true;
    };

    fish = super.fish.overrideAttrs (oldAttrs: {
      cmakeFlags =
        (
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
          filteredFlags ++ [ newRustFlag ]
        )
        ++ [
          "-DFISH_INDENT_FOR_BUILDING_DOCS=${super.buildPackages.fish-indent-native}/bin/fish_indent"
          "-DSPHINX_EXECUTABLE=${super.buildPackages.sphinx}/bin/sphinx-build"
        ];
      patches = (oldAttrs.patches or [ ]) ++ [
        ./fish-custom-target-fix.patch
      ];
      preConfigure = (oldAttrs.preConfigure or "") + ''
        export RUST_BACKTRACE=1
      '';
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

    python3 = (
      super.python3.override {
        packageOverrides = final: prev: {
          setuptools-rust = prev.setuptools-rust.overrideAttrs (oldAttrs: {
            setupHooks =
              if prev.python.pythonOnTargetForTarget == { } then
                null
              else
                super.replaceVars oldAttrs.setupHook.src {
                  pyLibDir =
                    if (oldAttrs.setupHook.stdenv.hostPlatform == oldAttrs.setupHook.stdenv.targetPlatform) then
                      "${prev.python}/lib/${prev.python.libPrefix}"
                    else
                      "${prev.python.pythonOnTargetForTarget}/lib/${prev.python.pythonOnTargetForTarget.libPrefix}";
                  cargoBuildTarget = oldAttrs.setupHook.stdenv.targetPlatform.rust.rustcTargetSpec;
                  cargoLinkerVar = oldAttrs.setupHook.stdenv.targetPlatform.rust.cargoEnvVarTarget;
                  targetLinker = "${super.stdenv.cc}/bin/${super.stdenv.cc.targetPrefix}cc";
                };
          });
        };
      }
    );
    python3Packages = self.python3.pkgs;

    maturin = super.maturin.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [ ])
        ++ (if isCrossTarget then [ ./maturin-custom-target-json.patch ] else [ ]);
    });

    git =
      if isCross then
        super.git.overrideAttrs (oldAttrs: {
          postPatch = (oldAttrs.postPatch or "") + ''
            substituteInPlace Makefile \
              --replace-fail "RUST_TARGET_DIR = target/${super.stdenv.hostPlatform.rust.rustcTargetSpec}/" \
                            "RUST_TARGET_DIR = target/${super.stdenv.hostPlatform.rust.cargoShortTarget}/"
          '';
        })
      else
        super.git;
  }
)
