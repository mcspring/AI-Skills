#!/usr/bin/env bash

for d in */; do                                                                                                                                                                        ─╯
  d="${d%/}"                 # 去掉末尾的 /
  [ -d "$d" ] || continue    # 确保是目录
  zip -r "${d}.zip" "$d"
done
