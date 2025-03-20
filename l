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
    # Använd netcat för att lyssna på port 25565 och hålla anslutningen öppen i 5 sekunder
    nc -l -p $PORT -w 5 > /dev/null 2>&1 && {
        echo "Anslutning upptäckt! Startar servern..."
        $START_SCRIPT &
        # Vänta 60 sekunder för att ge servern tid att starta
        sleep 60
    }
done
