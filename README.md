#!/usr/bin/env bash
set -e

### ==== Justera vid behov ====
MC_VERSION="1.21.1"      # Minecraft-version för servern (Paper)
RAM_MAX="2G"             # Max RAM till JVM (t.ex. 2G, 3G). Har du 8GB Pi: sätt 3G.
RAM_MIN="1G"             # Min RAM
MC_DIR="/opt/minecraft"  # Installationsmapp
MC_USER="mc"             # Systemanvändare som kör servern
PORT="25565"             # Serverport
### ===========================

echo "[1/7] Uppdaterar system och installerar beroenden…"
sudo apt update
sudo apt install -y curl jq openjdk-17-jdk screen

echo "[2/7] Skapar användare och mappar…"
if ! id -u "$MC_USER" >/dev/null 2>&1; then
  sudo useradd -r -m -d "$MC_DIR" -s /bin/bash "$MC_USER"
fi
sudo mkdir -p "$MC_DIR"
sudo chown -R "$MC_USER:$MC_USER" "$MC_DIR"

echo "[3/7] Hämtar senaste Paper build för $MC_VERSION…"
LATEST_BUILD=$(curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/${MC_VERSION}" | jq -r '.builds[-1]')
JAR_NAME="paper-${MC_VERSION}-${LATEST_BUILD}.jar"
sudo -u "$MC_USER" bash -c "
  cd '$MC_DIR'
  curl -fsSL -o 'paper.jar' 'https://api.papermc.io/v2/projects/paper/versions/${MC_VERSION}/builds/${LATEST_BUILD}/downloads/${JAR_NAME}'
"

echo "[4/7] Skapar startfil och EULA…"
sudo -u "$MC_USER" bash -c "cat > '$MC_DIR/start.sh' <<'EOF'
#!/usr/bin/env bash
cd \"\$(dirname \"\$0\")\"
exec java -Xms${RAM_MIN} -Xmx${RAM_MAX} -jar paper.jar nogui
EOF
chmod +x '$MC_DIR/start.sh'
echo 'eula=true' > '$MC_DIR/eula.txt'
"

echo "[5/7] Skapar standard server.properties om den saknas…"
if [ ! -f "$MC_DIR/server.properties" ]; then
  sudo -u "$MC_USER" bash -c "cat > '$MC_DIR/server.properties' <<EOF
server-port=${PORT}
motd=Pi 5 PaperMC Server
online-mode=true
view-distance=8
simulation-distance=8
max-players=10
enable-command-block=false
EOF"
fi

echo "[6/7] Skapar systemd-tjänst…"
sudo bash -c "cat > /etc/systemd/system/minecraft.service <<EOF
[Unit]
Description=Minecraft (Paper) server
After=network.target

[Service]
WorkingDirectory=${MC_DIR}
User=${MC_USER}
Group=${MC_USER}
Restart=always
RestartSec=10
ExecStart=${MC_DIR}/start.sh
Nice=5
SuccessExitStatus=0 143

[Install]
WantedBy=multi-user.target
EOF"

echo "[7/7] Startar och aktiverar tjänsten…"
sudo systemctl daemon-reload
sudo systemctl enable minecraft.service
sudo systemctl start minecraft.service

echo
echo "✅ Klart!"
echo "• Servern körs nu i bakgrunden som systemd-tjänst: sudo systemctl status minecraft"
echo "• Loggar live: sudo journalctl -u minecraft -f"
echo "• Stoppa/starta/boota: sudo systemctl stop|start|restart minecraft"
echo "• Servermapp: ${MC_DIR} (körs som användare ${MC_USER})"
echo "• Anslut från samma nät: $(hostname -I | awk '{print $1}'):${PORT}"
echo
echo "Tips:"
echo "– Ändra RAM i ${MC_DIR}/start.sh om du har 8GB Pi (t.ex. -Xmx3G)."
echo "– Öppna port 25565 i routern (port forwarding) om du vill spela över internet."
