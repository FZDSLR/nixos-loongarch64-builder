#!/usr/bin/env bash

ERROR_LOG=$(mktemp)
trap 'rm -f "$ERROR_LOG"' EXIT

nix eval --raw ".#nixosConfigurations.loongarch64.config.environment.systemPackages" \
  --apply "packages: builtins.concatStringsSep \"\n\" (map (pkg: pkg.drvPath) packages)" \
  | grep -E '^/nix/store/[0-9a-df-np-tv-z]{32}-[^/]+\.drv$' \
  | sort -u \
  | xargs -I{} sh -c '
    if ! nix-store --realise --verbose "$1"; then
      echo "$1" >> "$2"
      exit 1
    fi
  ' _ {} "$ERROR_LOG"

if [[ -s "$ERROR_LOG" ]]; then
  echo -e "\n以下包构建失败："
  cat "$ERROR_LOG"
  exit 1
else
  echo -e "\n所有包构建成功！"
  exit 0
fi
