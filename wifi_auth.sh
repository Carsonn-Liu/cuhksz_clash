#!/bin/bash

# ================= 配置区域 =================
USERNAME="" # 填入认证账号
PASSWORD=""  # 填入认证密码
# ===========================================

TEST_URL="http://captive.apple.com/hotspot-detect.html"
LOGIN_URL="https://ncecampus.cuhk.edu.cn:19008/portalauth/login"

echo "[-] 开始检测网络状态..."

# 1. 获取 captive 页面内容（不跟随重定向，因为是 HTML meta 跳转）
HTML_CONTENT=$(curl -s --max-time 10 "$TEST_URL")

# 2. 从 HTML 中提取 meta 重定向 URL（处理服务器通过 HTML 跳转的情况）
# 提取 meta 重定向 URL（处理空格、大小写、单双引号）
REDIRECT_URL=$(echo "$HTML_CONTENT" | grep -iE '<meta http-equiv="refresh" content="[^"]*"' | sed -E 's/.*content="[^"]*url=([^"]+)"[^>]*>.*/\1/i' | tr -d '[:space:]')

# 判断是否需要登录（若未获取到重定向 URL，说明已联网）
if [ -z "$REDIRECT_URL" ]; then
    echo "[!] 当前已连接互联网，无需登录。"
    exit 0
fi

echo "[-] 检测到重定向页面: $REDIRECT_URL"

# 3. 从提取的重定向 URL 中解析参数（uaddress、umac 等）
# 使用 urldecode 处理可能的编码字符（如 %2F 等）
UADDRESS=$(echo "$REDIRECT_URL" | awk -F 'uaddress=' '{print $2}' | awk -F '&' '{print $1}' | python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.stdin.readline().strip()))")
UMAC=$(echo "$REDIRECT_URL" | awk -F 'umac=' '{print $2}' | awk -F '&' '{print $1}' | python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.stdin.readline().strip()))")

# 检查参数是否提取成功
if [ -z "$UADDRESS" ] || [ -z "$UMAC" ]; then
    echo "[!] 错误：无法从重定向 URL 中提取 uaddress 或 umac。"
    echo "    重定向 URL: $REDIRECT_URL"
    exit 1
fi

echo "[-] 提取参数成功 - IP: $UADDRESS, MAC: $UMAC"

# 4. 发送登录请求（增加 User-Agent 模拟浏览器，避免被服务器拦截）
echo "[-] 正在发送登录请求..."
RESPONSE=$(curl -s --max-time 15 -X POST "$LOGIN_URL" \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Safari/537.36" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "userName=$USERNAME" \
    -d "userPass=$PASSWORD" \
    -d "agreed=1" \
    -d "uaddress=$UADDRESS" \
    -d "umac=$UMAC" \
    -d "authType=1")  # authType 根据实际接口调整，若失败可尝试删除或修改

# 5. 验证登录结果（根据实际响应调整判断条件）
if echo "$RESPONSE" | grep -qiE "success|登录成功|connected|认证成功"; then
    echo "[+] 登录成功！"
    exit 0
else
    echo "[!] 登录失败，服务器返回："
    echo "$RESPONSE"
    exit 1
fi
