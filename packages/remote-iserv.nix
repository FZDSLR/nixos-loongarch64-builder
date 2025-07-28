{
  mkDerivation,
  base,
  ghci,
  lib,
  ghc,
}:
mkDerivation {
  pname = "remote-iserv";
  version = ghc.version;
  src = ghc.src;
  sourceRoot = "${ghc.src.name}/utils/remote-iserv";
  preConfigure = ''
    cp remote-iserv.cabal.in remote-iserv.cabal
    sed -i \
      -e "s/@ProjectVersion@/${ghc.version}/g" \
      -e "s/@ProjectVersionMunged@/${ghc.version}/g" \
      remote-iserv.cabal
  '';
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    base
    ghci
  ];
  description = "iserv allows GHC to delegate Template Haskell computations";
  license = lib.licenses.bsd3;
  mainProgram = "remote-iserv";
}
