#!/usr/bin/env bash

ERROR_LOG=$(mktemp)
ERROR_LOGS=$(mktemp)
trap 'rm -f "$ERROR_LOG" "$ERROR_LOGS"' EXIT

nix eval --raw ".#nixosConfigurations.loongarch64.config.environment.systemPackages" \
  --apply "packages: builtins.concatStringsSep \"\n\" (map (pkg: pkg.drvPath) packages)" \
  | grep -E '^/nix/store/[0-9a-df-np-tv-z]{32}-[^/]+\.drv$' \
  | sort -u \
  | xargs -I{} sh -c '
      drv_path="$1"
      pkg_name=$(basename "$drv_path" | sed -E "s/^[^-]*-([^.]*)\.drv$/\1/")
      echo "开始构建 $pkg_name"

      log_file=$(mktemp)
      if nix-store --realise --verbose "$drv_path" > "$log_file" 2>&1; then
        # result_path=$(nix-store --query --binding out "$drv_path")
        # echo "上传 $pkg_name 到Cachix"
        # cachix push my-cache "$result_path"
        rm -f "$log_file"
      else
        echo "$drv_path" >> "$2"
        echo "$pkg_name $log_file" >> "$3"
        exit 1
      fi
    ' _ {} "$ERROR_LOG" "$ERROR_LOGS"

if [[ -s "$ERROR_LOG" ]]; then
  echo -e "\n以下包构建失败："
  cat "$ERROR_LOG"

  echo -e "\n构建失败日志输出："
  while read -r pkg_name log_file; do
    echo "=============================================="
    echo "构建失败详情：$pkg_name"
    echo "=============================================="
    cat "$log_file"
    rm -f "$log_file"
  done < "$ERROR_LOGS"

  exit 1
else
  echo -e "\n所有包构建成功！"
  exit 0
fi
