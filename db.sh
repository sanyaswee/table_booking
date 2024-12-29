#!/bin/bash

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
