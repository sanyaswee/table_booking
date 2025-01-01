# Provide the database socket port
DB_PORT=7000

# Read the first line of the HTTP request (e.g., GET /book HTTP/1.1)
REQUEST_DATA=""
read REQUEST_DATA

# Extract the requested route and arguments (URL path, e.g., /book or /cancel)
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
        # Get today in order to set minimal date for booking a table
        today=$(date +"%Y-%m-%d")
        ;;
    "/cancel")
        FILE="templates/cancel.html"
        STATUS="200 OK"
        ;;
    "/canceled")
        FILE="templates/canceled.html"
        STATUS="200 OK"

        # Extract required arguments
        IFS="&" # Internal Field Separator for splitting key-value pairs
        for pair in $ARGS; do
            key="${pair%%=*}"      # Extract key (part before '=')
            value="${pair#*=}"     # Extract value (part after '=')
            
            case $key in
                # rid = Reservation ID
                rid) rid="$value" ;;
            esac
        done

        # Construct SQL query and get DB response
        SQL="SELECT name, reservation_date, restaurant FROM reservations WHERE id=$rid; DELETE FROM reservations WHERE id=$rid;"
        db_resp=$(echo "$SQL" | nc localhost $DB_PORT)
        
        # Parse DB response
        name=$(echo "$db_resp" | awk "{print \$4}")
        date=$(echo "$db_resp" | awk "{print \$5}")
        restaurant=$(echo "$db_resp" | awk "{ s = \"\"; for (i = 6; i <= NF; i++) s = s \$i \" \"; print s }")
        
        ;;
    "/reservation")
    	FILE="templates/reservation.html"
    	STATUS="200 OK"
    	
        # Extract required arguments
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
        done
        
        # Replace snake_case name into actual name
	    case $restaurant in
	    	baco_tell) restaurant="Baco Tell" ;;
	    	kurger_bing) restaurant="Kurger Bing" ;;
	    	waysub) restaurant="WaySub" ;;
	    	mcronalds) restaurant="McRonalds" ;;
	    esac
		
        # Construct SQL query and get DB response
        SQL="INSERT INTO reservations (name, amount_of_people, reservation_date, restaurant) VALUES (\"$name\", $amount_of_people, \"$date\", \"$restaurant\"); SELECT LAST_INSERT_ID();"
		db_resp=$(echo "$SQL" | nc localhost $DB_PORT)
		
        # Extrcat reservation ID from resonse
        reservation_id=$(echo "$db_resp" | awk "{print \$2}")
     	
        ;;
    "/reservations")
        FILE="templates/reservations.html"
        STATUS="200 OK"
        
        # Construct SQL query and get response
        SQL="SELECT id FROM reservations;"
        db_resp=$(echo "$SQL" | nc localhost $DB_PORT)
        
        # Get ids from response
        ids=$(echo "$db_resp" | awk "{ s = \"\"; for (i = 2; i <= NF; i++) s = s \$i \" \"; print s }")
        
        reservations=""
        for i in $ids; do
            # Construct another query to get full data by a particular ID
            SQL="SELECT name, reservation_date, restaurant FROM reservations WHERE id=$i;"
            db_resp=$(echo "$SQL" | nc localhost $DB_PORT)
            
            # Parse response
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
    # Load HTML content
    RESPONSE_BODY=$(cat "$FILE")
    # Evaluate variables (e.g. $name)
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