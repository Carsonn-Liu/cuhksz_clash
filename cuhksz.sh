#!/usr/bin/env bash
set -euo pipefail

MIHOMO_ADDR="127.0.0.1"
MIHOMO_PORT="9090"
MIHOMO_SECRET=""
MIHOMO_SELECTOR="🎓 校内专线"
MIHOMO_PROXY_ON="🏫 cuhksz"
MIHOMO_PROXY_OFF="DIRECT"

# VPN 配置（仅需修改 VPN_PASSWORD）
VPN_USER=""  # <-- 在这里填入你的实际用户名
VPN_PASSWORD=""  # <-- 在这里填入你的实际密码
VPN_GROUP="CUHK(SZ)"
VPN_GATEWAY="vpn.cuhk.edu.cn"
SOCKS_PORT="11080"


urlencode() {
  python3 - "$1" << 'EOF'
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1]))
EOF
}

mihomo_api() {
  local method="$1"
  local path="$2"
  local data="${3:-}"
  local url="http://$MIHOMO_ADDR:$MIHOMO_PORT$path"
  local auth_header=()
  if [[ -n "$MIHOMO_SECRET" ]]; then
    auth_header=(-H "Authorization: Bearer $MIHOMO_SECRET")
  fi
  if [[ -n "$data" ]]; then
    curl -sS -X "$method" "$url" "${auth_header[@]}" -H "Content-Type: application/json" --data "$data" > /dev/null
  else
    curl -sS -X "$method" "$url" "${auth_header[@]}" > /dev/null
  fi
}

set_mihomo_selector() {
  local target="$1"
  local encoded_selector=$(urlencode "$MIHOMO_SELECTOR")
  mihomo_api "PUT" "/proxies/$encoded_selector" "{\"name\":\"$target\"}"
  echo "mihomo: 已将 [$MIHOMO_SELECTOR] 切换为 [$target]"
}


cleanup() {
  echo -e "\nVPN 断开，恢复 [$MIHOMO_SELECTOR] 为 [$MIHOMO_PROXY_OFF]..."
  set_mihomo_selector "$MIHOMO_PROXY_OFF" || true
}
trap cleanup EXIT HUP INT TERM

echo "VPN 即将连接，将 [$MIHOMO_SELECTOR] 切到 [$MIHOMO_PROXY_ON]..."
set_mihomo_selector "$MIHOMO_PROXY_ON"

echo "开始连接 CUHKSZ VPN..."
# 核心：通过 echo 将密码传递给 openconnect（已填入你的密码变量）
echo "$VPN_PASSWORD" | openconnect \
  -u "$VPN_USER" \
  --authgroup="$VPN_GROUP" \
  --script-tun \
  --script="ocproxy -D $SOCKS_PORT" \
  --passwd-on-stdin \
  "$VPN_GATEWAY"

echo "openconnect 已退出。"