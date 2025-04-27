self: super: {
  libressl = (
    super.libressl.overrideAttrs (
      finalAttrs: previousAttrs: {
        src = super.fetchgit {
          url = "https://github.com/libressl/portable.git";
          rev = "73779a46bf49c4f53cc4b81993135a7408a01963";
          sha256 = "sha256-3ffzz2gdjKbsxJk765ZTuFYDldPmii7Zvcu7sNf9i8w=";
        };
        postPatch = ''
          patchShebangs tests/
        '';
        preConfigure = ''
          ./autogen.sh \
          rm -f configure \
          substituteInPlace CMakeLists.txt \
            --replace 'exec_prefix \''${prefix}' "exec_prefix ${placeholder "bin"}" \
            --replace 'libdir      \''${exec_prefix}' 'libdir \''${prefix}'
        '';
        nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [super.git];
      }
    )
  );
}
