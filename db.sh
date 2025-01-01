#!/bin/bash

# Set the port to listen on
PORT=7000

# Database login info
USER="table_booking"
PWD=$(cat pwd.txt)
HOST="localhost"
DB="table_booking"

# Clear outdated reservations
echo "Clearing outdated reservations..."
QUERY="DELETE FROM reservations WHERE reservation_date < CURRENT_DATE;"
echo $(mysql -u $USER -p$PWD -h $HOST -D $DB -e "$QUERY")

# Load processing script
handler=$(cat "db_query_processor.sh")

# Main loop to listen for incoming HTTP requests
echo "Starting database server on port $PORT..."
echo "Send your SQL queries on localhost:$PORT"
while true; do
	ncat -l -p 7000 -c "$handler"
done