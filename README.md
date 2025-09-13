# 1) Döda eventuella manuella instanser
pgrep -af java
sudo pkill -f 'java.*paper.jar'   # kör om du ser en rad för paper/jar

# 2) Starta om systemd-tjänsten
sudo systemctl restart minecraft
sudo systemctl status minecraft

# 3) Verifiera att porten lyssnar
ss -tulpn | grep 25565
