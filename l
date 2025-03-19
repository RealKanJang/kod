#!/bin/bash

SERVER_DIR="/home/melvin/Desktop/minecraft-server"
START_SCRIPT="$SERVER_DIR/start.sh"
PORT=25565

# Kontrollera om servern redan körs
if pgrep -f "java -Xmx4096M -Xms4096M -jar paper.jar nogui" > /dev/null; then
    echo "Servern körs redan!"
    exit 0
fi

echo "Lyssnar på port $PORT för anslutningar..."

while true; do
    nc -l $PORT > /dev/null 2>&1
    echo "Anslutning upptäckt! Startar servern..."
    $START_SCRIPT &
    sleep 30
done




