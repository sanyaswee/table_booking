#!/bin/bash

# Set the port to listen on
PORT=7000

# Main loop to listen for incoming HTTP requests
echo "Starting database server on port $PORT..."
echo "Send your SQL queries on localhost:$PORT"

while true; do
	ncat -l -p 7000 -c '
		USER="table_booking"
		PWD=$(cat pwd.txt)
		HOST="localhost"
		DB="table_booking"

		read QUERY
		echo $(mysql -u $USER -p$PWD -h $HOST -D $DB -e "$QUERY")
	'
done
