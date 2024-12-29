#!/bin/bash

# Set the port to listen on
PORT=8080

# Main loop to listen for incoming HTTP requests
echo "Starting web server on port $PORT..."
echo "Visit http://localhost:$PORT to view the pages."

# Infinite loop to handle incoming connections
while true; do
    ncat -l -p $PORT -c '
	# Read the first line of the HTTP request (e.g., GET /book HTTP/1.1)
        REQUEST_DATA=""
        while IFS= read REQUEST_DATA; do
		break
        done

        # Extract the requested route (URL path, e.g., /book or /cancel)
        ROUTE_ARGS=$(echo "$REQUEST_DATA" | awk "{print \$2}")
        ROUTE="${ROUTE_ARGS%%\?*}"
        ARGS="${ROUTE_ARGS#*\?}"
        
        # Determine which file to serve based on the requested route
        case "$ROUTE" in
            "/")
                FILE="templates/homepage.html"
                STATUS="200 OK"
                ;;
            "/book")
                FILE="templates/book.html"
                STATUS="200 OK"
                ;;
            "/cancel")
                FILE="templates/cancel.html"
                STATUS="200 OK"
                ;;
            "/reservation")
            	FILE="templates/reservation.html"
            	STATUS="200 OK"
            	IFS="&" # Internal Field Separator for splitting key-value pairs
		for pair in $ARGS; do
		    key="${pair%%=*}"      # Extract key (part before '=')
		    value="${pair#*=}"     # Extract value (part after '=')
		    
		    case $key in
			name) name="$value" ;;
			amount_of_people) amount_of_people="$value" ;;
			date) date="$value" ;;
			restaurant) restaurant="$value" ;;
		    esac
		    case $restaurant in
		    	baco_tell) restaurant="Baco Tell" ;;
		    	kurger_bing) restaurant="Kurger Bing" ;;
		    	waysub) restaurant="WaySub" ;;
		    	mcronalds) restaurant="McRonalds" ;;
		    esac
		done
		SQL="INSERT INTO reservations (name, amount_of_people, reservation_date, restaurant) VALUES (\"$name\", $amount_of_people, \"$date\", \"$restaurant\"); SELECT LAST_INSERT_ID();"
		db_resp=$(echo "$SQL" | nc localhost 7000)
		reservation_id=$(echo "$db_resp" | awk "{print \$2}")
             	;;
            *)
                FILE="templates/404.html"
                STATUS="404 Not Found"
                ;;
        esac
        
        # Check if the requested file exists
        if [ -f "$FILE" ]; then
            RESPONSE_BODY=$(cat "$FILE")
            RESPONSE_BODY=$(eval "echo \"$RESPONSE_BODY\"")
        else
            RESPONSE_BODY="<html><body><h1>404 Not Found</h1></body></html>"
        fi

        # Send the HTTP response headers and body
        echo "HTTP/1.1 $STATUS\r"
        echo "Content-Type: text/html\r"
        echo "Connection: close\r"
        echo "\r"  # This is the required blank line separating headers from the body
        echo "$RESPONSE_BODY"
    '
done
