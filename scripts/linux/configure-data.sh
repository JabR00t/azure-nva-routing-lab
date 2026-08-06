#!/usr/bin/env bash
set -euo pipefail

sudo mkdir -p /opt/data-tier

sudo tee /opt/data-tier/index.html >/dev/null <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Data Tier</title>
</head>
<body>
    <h1>Data Tier</h1>
    <p>Linux data VM is reachable on TCP port 1433.</p>
</body>
</html>
EOF

sudo tee /etc/systemd/system/data-tier.service >/dev/null <<'EOF'
[Unit]
Description=Data Tier Test Listener
After=network.target

[Service]
WorkingDirectory=/opt/data-tier
ExecStart=/usr/bin/python3 -m http.server 1433 --bind 0.0.0.0
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now data-tier.service

sudo systemctl status data-tier.service --no-pager
sudo ss -lntp | grep 1433