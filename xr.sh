#!/bin/bash

set -e

echo "== Xray install script =="

# Проверка root
if [ "$EUID" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

XRAY_CONFIG_DIR="/usr/local/etc/xray"
XRAY_CONFIG_FILE="$XRAY_CONFIG_DIR/config.json"

echo "[1/4] Установка зависимостей"
apt update -y
apt install -y curl ca-certificates

echo "[2/4] Установка Xray (официальный скрипт)"
bash <(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)

echo "[3/4] Создание конфига"

mkdir -p "$XRAY_CONFIG_DIR"

cat > "$XRAY_CONFIG_FILE" << 'EOF'
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "inbound-443",
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "shadowsocks",
      "settings": {
        "method": "chacha20-ietf-poly1305",
        "password": "l0l99@",
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "shadowsocks",
      "tag": "1xeammnp",
      "settings": {
        "servers": [
          {
            "address": "91.84.100.81",
            "port": 5555,
            "password": "zl18dzqoCTQ3OCrLxylVplGaTMzm7kUM+t2ZEwbOw5s=:ejwgFBs+u/JnuPLG3C51OQ9ZlBLLvh4AyG7YdQJTNZE=",
            "method": "2022-blake3-aes-256-gcm",
            "uot": true
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        }
      }
    },
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "network": "tcp,udp",
        "inboundTag": [
          "inbound-443"
        ],
        "outboundTag": "1xeammnp"
      }
    ]
  }
}
EOF

echo "[4/4] Запуск Xray"

systemctl daemon-reexec
systemctl enable xray
systemctl restart xray

echo "======================================"
echo "Xray УСТАНОВЛЕН И ЗАПУЩЕН"
echo "Inbound : Shadowsocks 443 TCP/UDP"
echo "Outbound: 1xeammnp"
echo "======================================"
