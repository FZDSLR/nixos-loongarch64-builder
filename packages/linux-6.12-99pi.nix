{
  lib,
  src,
  pkgs,
  stdenv,
  ubootTools,
  linuxManualConfig,
  configfile ? null,
  dtbname ? "ls2k300_99pi_tf",
  ...
}:
let
  kernelSrc = pkgs.fetchgit {
    url = "https://gitee.com/open-loongarch/linux-6.12.git";
    rev = "012dbfc9b1a9ddd8be883268e90eae5e1ee278db";
    sha256 = "sha256-6buUOZ2ojpTn0ZJIpDyJPotA0zhiMcfLmM85LciIIis=";
  };
  kernelConfig =
    let
      baseConfig =
        if configfile != null then
          configfile
        else
          ./99pi-config;

      overrideConfig = pkgs.writeText "override-config" ''
        CONFIG_DTB_MATCH_BY_BOARD_NAME=n
        CONFIG_BUILTIN_DTB_NAME="${dtbname}"
      '';
    in
    pkgs.runCommand "kernel-config" {} ''
    cp ${baseConfig} config.work
    chmod u+w config.work
    sed -i '/CONFIG_BUILTIN_DTB_NAME/d' config.work
    cat ${overrideConfig} >> config.work
    mv config.work "$out"
    '';
in
(linuxManualConfig {
  version = "6.12.0";
  modDirVersion = "6.12.0.lsgd";

  src = kernelSrc;

  configfile = kernelConfig;

  allowImportFromDerivation = true;
}).overrideAttrs
  (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ ubootTools ];
    postPatch = ''
      substituteInPlace drivers/net/can/ls_canfd/Makefile \
        --replace 'cp $(obj)/lscanfd_dma.o_shipped' 'cp $(src)/lscanfd_dma.o_shipped' \
        --replace 'cp $(obj)/lscanfd_dma.o_shipped_rt' 'cp $(src)/lscanfd_dma.o_shipped_rt' \
        --replace 'cp $(obj)/lscanfd_platform.o_shipped' 'cp $(src)/lscanfd_platform.o_shipped' \
        --replace 'cp $(obj)/lscanfd_platform.o_shipped_rt' 'cp $(src)/lscanfd_platform.o_shipped_rt'
    '';
    # override installPhase due to lack support for make uinstall for loongarch
    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp $buildRoot/arch/loongarch/boot/uImage $out/
      cp $buildRoot/System.map $out/
      cp $buildRoot/.config $out/config

      runHook postInstall
    '';
  })
