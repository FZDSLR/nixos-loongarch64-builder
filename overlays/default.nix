self: super: {
  libressl = (
    super.libressl.overrideAttrs (
      finalAttrs: previousAttrs: {
        src = super.fetchgit {
          url = "https://github.com/libressl/portable.git";
          rev = "031c2f1722f9af10299de3d22ff3c1467d541241";
          sha256 = "sha256-ieNEEpO8S+yQ658oPveZ3b0VzmS1k6c3yExHABnYQuY=";
        };
      }
    )
  );
}
