{
  mkDerivation,
  array,
  base,
  binary,
  bytestring,
  containers,
  deepseq,
  ghci,
  lib,
  unix,
  ghc,
}:
mkDerivation {
  pname = "iserv";
  version = ghc.version;
  src = ghc.src;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    array
    base
    binary
    bytestring
    containers
    deepseq
    ghci
    unix
  ];
  sourceRoot = "${ghc.src.name}/utils/iserv";
  preConfigure = ''
    cp iserv.cabal.in iserv.cabal
    sed -i \
      -e "s/@ProjectVersion@/${ghc.version}/g" \
      -e "s/@ProjectVersionMunged@/${ghc.version}/g" \
      iserv.cabal
  '';
  description = "iserv allows GHC to delegate Template Haskell computations";
  license = lib.licenses.bsd3;
  mainProgram = "iserv";
}
