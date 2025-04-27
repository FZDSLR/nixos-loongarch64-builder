#!/usr/bin/env bash

nix eval --raw ".#nixosConfigurations.loongarch64.config.environment.systemPackages" \
  --apply "builtins.concatStringsSep \"\n\"" 2>/dev/null \
  | grep -E '^/nix/store/[a-z0-9]{32}-[^\s]+' \
  | sort -u \
  | xargs -I{} nix build --print-build-logs {}
