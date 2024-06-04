#!/bin/bash

# MySQL credentials
DB_USER="your_db_username"
DB_PASSWORD="your_db_password"
DB_NAME="user_db"
DB_TABLE="users"
LOG_FILE="insert_user.log"

# Function to show usage
usage() {
    echo "Usage: $0 firstname lastname username email age salary"
    exit 1
}

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $message" >> "$LOG_FILE"
}

# Check if correct number of arguments are provided
if [ "$#" -ne 6 ]; then
    usage
fi

# Assign arguments to variables
FIRSTNAME=$1
LASTNAME=$2
USERNAME=$3
EMAIL=$4
AGE=$5
SALARY=$6

# Validate and sanitize inputs
sanitize_input() {
    local input="$1"
    echo "$input" | sed 's/[^a-zA-Z0-9@._-]//g'
}

FIRSTNAME=$(sanitize_input "$FIRSTNAME")
LASTNAME=$(sanitize_input "$LASTNAME")
USERNAME=$(sanitize_input "$USERNAME")
EMAIL=$(sanitize_input "$EMAIL")

# Validate that age is an integer
if ! [[ "$AGE" =~ ^[0-9]+$ ]]; then
    log_message "Error: Age must be an integer."
    echo "Error: Age must be an integer."
    exit 1
fi

# Validate that salary is a number (integer or decimal)
if ! [[ "$SALARY" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
    log_message "Error: Salary must be a number."
    echo "Error: Salary must be a number."
    exit 1
fi

# Connect to MySQL and insert data using prepared statements
mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" <<EOF
DELIMITER //

BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET @error = 1;
        CALL write_log(CONCAT('Failed to insert user details: ', SQLSTATE, ' - ', MESSAGE_TEXT));
    END;

    DECLARE EXIT HANDLER FOR SQLWARNING
    BEGIN
        ROLLBACK;
        SET @error = 1;
        CALL write_log(CONCAT('Warning: ', SQLSTATE, ' - ', MESSAGE_TEXT));
    END;

    START TRANSACTION;

    SET @error = 0;

    INSERT INTO $DB_TABLE (firstname, lastname, username, email, age, salary)
    VALUES ('$FIRSTNAME', '$LASTNAME', '$USERNAME', '$EMAIL', $AGE, $SALARY);

    IF @error = 0 THEN
        COMMIT;
        CALL write_log('User details inserted successfully.');
    ELSE
        ROLLBACK;
        CALL write_log('Failed to insert user details.');
    END IF;
END//

DELIMITER ;
EOF

# Check if the insert was successful
if [ $? -eq 0 ]; then
    log_message "User details inserted successfully."
    echo "User details inserted successfully."
else
    log_message "Failed to insert user details."
    echo "Failed to insert user details."
    exit 1
fi


# Example to pass data
# chmod +x insert_user.sh

# ./insert_user.sh John Doe johndoe john.doe@example.com 30 50000

# If you run via bash then;

# bash insert_user.sh John Doe johndoe john.doe@example.com 30 50000
