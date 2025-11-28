#!/bin/bash

# ================= 配置区域 =================
USERNAME="" # 请在此处填入校园网认证用户名
PASSWORD="" # 请在此处填入校园网认证密码
# ===========================================

TEST_URL="http://captive.apple.com/hotspot-detect.html"
LOGIN_URL="https://ncecampus.cuhk.edu.cn:19008/portalauch/login"

echo "[-] 开始检测网络状态..."

# 1. 获取重定向 URL
# 使用 -w %{redirect_url} 获取重定向地址，使用 -o /dev/null 丢弃内容
REDIRECT_URL=$(curl -s -L -w "%{url_effective}" -o /dev/null "$TEST_URL")

# 检查是否已经联网 (如果最终 URL 还是 captive.apple.com，说明没有被拦截，即已联网)
if [[ "$REDIRECT_URL" == *"captive.apple.com"* ]]; then
    echo "[!] 当前似乎已连接互联网，跳过登录。"
    exit 0
fi

echo "[-] 检测到重定向页面: $REDIRECT_URL"

# 2. 提取参数 (使用 grep 和 sed)
# 提取 uaddress
UADDRESS=$(echo "$REDIRECT_URL" | grep -o 'uaddress=[^&]*' | cut -d= -f2)
# 提取 umac
UMAC=$(echo "$REDIRECT_URL" | grep -o 'umac=[^&]*' | cut -d= -f2)

if [[ -z "$UADDRESS" || -z "$UMAC" ]]; then
    echo "[!] 错误：无法从链接中提取 uaddress 或 umac。"
    exit 1
fi

echo "[-] 提取成功 - IP: $UADDRESS, MAC: $UMAC"

# 3. 发送 POST 请求登录
echo "[-] 正在发送登录请求..."
RESPONSE=$(curl -s -X POST "$LOGIN_URL" \
    -d "userName=$USERNAME" \
    -d "userPass=$PASSWORD" \
    -d "agreed=1" \
    -d "uaddress=$UADDRESS" \
    -d "umac=$UMAC" \
    -d "authType=1")

echo "[+] 登录请求已发送，服务器返回："
echo "$RESPONSE"
