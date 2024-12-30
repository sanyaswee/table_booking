#!/bin/bash

# Set the port to listen on
PORT=8080

# Main loop to listen for incoming HTTP requests
echo "Starting web server on port $PORT..."
echo "Visit http://localhost:$PORT to view the pages."

# Infinite loop to handle incoming connections
while true; do
    ncat -l -p $PORT -c '
        DB_PORT=7000
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
                today=$(date +"%Y-%m-%d")
                ;;
            "/cancel")
                FILE="templates/cancel.html"
                STATUS="200 OK"
                ;;
            "/canceled")
                FILE="templates/canceled.html"
                STATUS="200 OK"
                for pair in $ARGS; do
                    key="${pair%%=*}"      # Extract key (part before '=')
                    value="${pair#*=}"     # Extract value (part after '=')
                    
                    case $key in
                        rid) rid="$value" ;;
                    esac
                done
                SQL="SELECT name, reservation_date, restaurant FROM reservations WHERE id=$rid; DELETE FROM reservations WHERE id=$rid;"
                db_resp=$(echo "$SQL" | nc localhost $DB_PORT)
                name=$(echo "$db_resp" | awk "{print \$4}")
                date=$(echo "$db_resp" | awk "{print \$5}")
                restaurant=$(echo "$db_resp" | awk "{ s = \"\"; for (i = 6; i <= NF; i++) s = s \$i \" \"; print s }")
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
        		db_resp=$(echo "$SQL" | nc localhost $DB_PORT)
        		reservation_id=$(echo "$db_resp" | awk "{print \$2}")
             	;;
            "/reservations")
                FILE="templates/reservations.html"
                STATUS="200 OK"
                SQL="SELECT id FROM reservations;"
                db_resp=$(echo "$SQL" | nc localhost $DB_PORT)
                ids=$(echo "$db_resp" | awk "{ s = \"\"; for (i = 2; i <= NF; i++) s = s \$i \" \"; print s }")
                reservations=""
                for i in $ids; do
                    SQL="SELECT name, reservation_date, restaurant FROM reservations WHERE id=$i;"
                    db_resp=$(echo "$SQL" | nc localhost $DB_PORT)
                    name=$(echo "$db_resp" | awk "{print \$4}")
                    date=$(echo "$db_resp" | awk "{print \$5}")
                    restaurant=$(echo "$db_resp" | awk "{ s = \"\"; for (i = 6; i <= NF; i++) s = s \$i \" \"; print s }")
                    reservations="${reservations}<tr><td>$name</td><td>$restaurant</td><td>$date</td></tr>"
                done
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
