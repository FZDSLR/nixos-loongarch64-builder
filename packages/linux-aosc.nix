{
  stdenv,
  fetchgit,
  pkgsBuildBuild,
  linuxConfig,
  linuxManualConfig,
  ...
}:
let
  linuxRev = "6c7ad315b8510535287784e2af23b46d14ae51f8";
  linuxSha256 = "sha256-5AbLLdTSZJmV67ytPieNkx97TTDDYD2hVnvpOt7tF+8=";
  linuxVersion = "6.17.7";
  linuxModDirVersion = "6.17.7";

  linuxSrc = fetchgit {
    url = "https://github.com/AOSC-Tracking/linux.git";
    rev = linuxRev;
    sha256 = linuxSha256;
  };
in
(
  (linuxManualConfig {
    version = linuxVersion;
    modDirVersion = linuxModDirVersion;
    src = linuxSrc;
    configfile = (
      linuxConfig {
        src = linuxSrc;
        version = linuxVersion;
        makeTarget = if stdenv.hostPlatform.isLoongArch64 then "loongson_2k0300_defconfig" else "defconfig";
      }
    );
    allowImportFromDerivation = true;
  }).overrideAttrs
  (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgsBuildBuild.ubootTools ];
    patches = (old.patches or [ ]) ++ [
      ./aosc-linux-forever-pi-tf-support.patch
    ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp $buildRoot/arch/loongarch/boot/uImage $out/
      cp $buildRoot/System.map $out/
      cp $buildRoot/.config $out/config
      runHook postInstall
    '';
  })
)
