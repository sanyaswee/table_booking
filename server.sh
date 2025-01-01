#!/bin/bash

# Set the port to listen on
PORT=8080

# Load processing script
handler=$(cat "request_processor.sh")

# Main loop to listen for incoming HTTP requests
echo "Starting web server on port $PORT..."
echo "Visit http://localhost:$PORT to view the website."

# Infinite loop to handle incoming connections
while true; do
    ncat -l -p $PORT -c "$handler"
done
