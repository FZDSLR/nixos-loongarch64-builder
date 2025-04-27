self: super: {
  libressl = (
    super.libressl.overrideAttrs (
      finalAttrs: previousAttrs: {
        patches = [
          (super.fetchurl {
            url = "https://patch-diff.githubusercontent.com/raw/libressl/portable/pull/1146.patch";
            sha256 = "12vn8rpxndsmrwnf713h85jwh1xs3d8kw83cy30pqiifn1iaf3nv";
          })
        ];
      }
    )
  );
}
