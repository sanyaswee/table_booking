# TableBooking
## About
This is a **pure bash** implementation of a simple web application, that includes **database interaction via sockets**.  

The application is supposed to run on Linux distributions, particularly on **Debian 12**.
## Installation and run
After cloning the repo, before the first run, you need to take some additional steps
### 1. Dependencies
This project requires the following packages to be installed:
- ncat
- MariaDB  

To install them:
```
sudo apt update
sudo apt install ncat
sudo apt install mariadb-server
```
### 2. Database preparation
#### 2.1. Create user and schema
After installing MariaDB, you need to create a schema and user `table_booking` and grant all permissions on that schema:
```
-- Create the schema
CREATE SCHEMA table_booking;

-- Create the user
CREATE USER 'table_booking'@'localhost' IDENTIFIED BY 'your_secure_password';

-- Grant all privileges on the schema to the user
GRANT ALL PRIVILEGES ON table_booking.* TO 'table_booking'@'localhost';

-- Apply the changes
FLUSH PRIVILEGES;

```

**Store your password in the file named `pwd.txt`**
#### 2.2. Create a table
Create a table called `reservations`:
```
CREATE TABLE reservations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    amount_of_people INT NOT NULL,
    reservation_date DATE NOT NULL,
    restaurant VARCHAR(255) NOT NULL
);
```
### 3. Permissions
You need to make files `server.sh` and `db.sh` executable:
```
chmod +x server.sh
chmod +x db.sh
```
### 4. Run
To run the application, open **two terminals**:  
- For the first terminal: `./server.sh`
- For the second: `./db.sh`

Now you should be able to access the application on `localhost:8080`
## Hint
While `db.sh` is running, you can execute any SQL query in another terminal like this:
```
echo "<your query here>" | nc localhost 7000
```
