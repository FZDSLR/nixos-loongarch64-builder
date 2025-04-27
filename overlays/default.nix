self: super: {
  libressl = (
    super.libressl.overrideAttrs (
      finalAttrs: previousAttrs: {
        src = super.fetchgit {
          url = "https://github.com/libressl/portable.git";
          rev = "031c2f1722f9af10299de3d22ff3c1467d541241";
          sha256 = "sha256-1rj2v0ch0iscr0vsg4xmck71bgfxk7vkwa4zxf8fqjxwjc949qw9";
        };
      }
    )
  );
}
