#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting installation for ReverseMouseScroll...${NC}"

# 1. 创建临时下载目录
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# 2. 定义下载地址 (指向 Latest Release)
# 注意：这里已经填好了你的用户名
REPO_URL="https://github.com/CyrusZhang23/ReverseMouseScroll/releases/latest/download/ReverseMouseScroll.tar.gz"

echo "⬇️  Downloading latest binary..."
curl -L -o app.tar.gz "$REPO_URL"

if [ $? -ne 0 ]; then
    echo "❌ Download failed. Please check your internet connection."
    exit 1
fi

# 3. 解压
tar -xzf app.tar.gz

# 4. 绕过 Gatekeeper (解除 macOS 对不明开发者的限制)
echo "🛡️  Bypassing Gatekeeper..."
xattr -cr ReverseMouseScroll

# 5. 安装与运行
echo "🔧 Installing..."
chmod +x ReverseMouseScroll

# 运行程序的安装模式
./ReverseMouseScroll --install

# 6. 清理垃圾
cd ..
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✨ All done! Enjoy natural scrolling for your mouse.${NC}"
