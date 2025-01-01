# DB login info
USER="table_booking"
PWD=$(cat pwd.txt)
HOST="localhost"
DB="table_booking"

# Read query respond
read QUERY
echo $(mysql -u $USER -p$PWD -h $HOST -D $DB -e "$QUERY")