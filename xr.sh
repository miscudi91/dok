#!/bin/bash

set -e

XRAY_DIR="/usr/local/etc/xray"
XRAY_BIN="/usr/local/bin/xray"
CONFIG_FILE="$XRAY_DIR/config.json"

echo "[1/5] Установка зависимостей"
apt update -y
apt install -y curl unzip jq

echo "[2/5] Загрузка Xray"
XRAY_URL=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest \
  | jq -r '.assets[] | select(.name | test("linux-64.zip")) | .browser_download_url')

curl -L "$XRAY_URL" -o /tmp/xray.zip
unzip -o /tmp/xray.zip -d /tmp/xray

install -m 755 /tmp/xray/xray $XRAY_BIN
install -d $XRAY_DIR

echo "[3/5] Создание конфигурации"

cat > $CONFIG_FILE << 'EOF'
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "inbound-443",
      "port": 443,
      "listen": "0.0.0.0",
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
      "tag": "1xeammnp",
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

echo "[4/5] Создание systemd-сервиса"

cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
Type=simple
ExecStart=$XRAY_BIN run -config $CONFIG_FILE
Restart=on-failure
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

echo "[5/5] Запуск Xray"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

echo "========================================"
echo "Xray установлен и запущен"
echo "Inbound: Shadowsocks TCP/UDP 443"
echo "Outbound tag: 1xeammnp"
echo "========================================"
