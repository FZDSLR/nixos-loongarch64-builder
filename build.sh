#!/usr/bin/env bash

nix eval --raw ".#nixosConfigurations.loongarch64.config.environment.systemPackages" \
  --apply "packages: builtins.concatStringsSep \"\n\" (map (pkg: pkg.drvPath) packages)" \
  | grep -E '^/nix/store/[0-9a-df-np-tv-z]{32}-[^/]+\.drv$' \
  | sort -u \
  | xargs -I{} nix build --print-build-logs {}
