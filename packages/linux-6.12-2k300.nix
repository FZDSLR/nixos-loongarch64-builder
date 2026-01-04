{
  lib,
  src,
  pkgs,
  stdenv,
  pkgsBuildBuild,
  linuxManualConfig,
  configfile ? ./loongson_2k300_config,
  ...
}:
(linuxManualConfig {
  version = "6.12.0";
  modDirVersion = "6.12.0.lsgd";

  src = pkgs.fetchgit {
    url = "https://gitee.com/open-loongarch/linux-6.12.git";
    rev = "aa348aad53dbd005c5cbbe16c63ea34ebf281fac";
    sha256 = "sha256-bMn2DiCx/5dQq7hwQwg2B9/dMw9ldB3WO6aPz0eNJOQ=";
  };

  configfile = configfile;

  allowImportFromDerivation = true;
}).overrideAttrs
  (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgsBuildBuild.ubootTools ];
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
