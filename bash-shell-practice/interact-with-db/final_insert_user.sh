#!/bin/bash

# Load environment variables from .env file
if [ ! -f .env ]; then
    echo ".env file not found!"
    exit 1
fi

export $(grep -v '^#' .env | xargs)

LOG_FILE="insert_user.log"
SUCCESS=0
FAILURE=1

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $message" >> "$LOG_FILE"
}

# Function to show usage
usage() {
    echo "Usage: $0 users.csv"
    exit $FAILURE
}

# Function to check dependencies
check_dependencies() {
    command -v expect >/dev/null 2>&1 || { echo "expect is required but it's not installed. Exiting."; exit $FAILURE; }
    command -v mysql >/dev/null 2>&1 || { echo "mysql is required but it's not installed. Exiting."; exit $FAILURE; }
}

# Function to sanitize input
sanitize_input() {
    local input="$1"
    echo "$input" | sed 's/[^a-zA-Z0-9@._-]//g'
}

# Function to validate age
validate_age() {
    local age="$1"
    if ! [[ "$age" =~ ^[0-9]+$ ]]; then
        log_message "Error: Age must be an integer."
        echo "Error: Age must be an integer."
        exit $FAILURE
    fi
}

# Function to validate salary
validate_salary() {
    local salary="$1"
    if ! [[ "$salary" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
        log_message "Error: Salary must be a number."
        echo "Error: Salary must be a number."
        exit $FAILURE
    fi
}

# Function to insert data into MySQL database
insert_data() {
    local firstname="$1"
    local lastname="$2"
    local username="$3"
    local email="$4"
    local age="$5"
    local salary="$6"

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
    VALUES ('$firstname', '$lastname', '$username', '$email', $age, $salary);

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

    if [ $? -eq $SUCCESS ]; then
        log_message "User details inserted successfully."
        echo "User details inserted successfully."
    else
        log_message "Failed to insert user details."
        echo "Failed to insert user details."
        exit $FAILURE
    fi
}

# Main function to process the CSV file and insert data
main() {
    # Check if correct number of arguments are provided
    if [ "$#" -ne 1 ]; then
        usage
    fi

    # Check dependencies
    check_dependencies

    local file="$1"

    # Check if the file exists
    if [ ! -f "$file" ]; then
        echo "File not found!"
        exit $FAILURE
    fi

    # Read the CSV file and insert each user
    while IFS=, read -r firstname lastname username email age salary; do
        # Skip the header line
        if [ "$firstname" == "firstname" ]; then
            continue
        fi

        # Sanitize and validate inputs
        firstname=$(sanitize_input "$firstname")
        lastname=$(sanitize_input "$lastname")
        username=$(sanitize_input "$username")
        email=$(sanitize_input "$email")
        validate_age "$age"
        validate_salary "$salary"

        # Insert data
        insert_data "$firstname" "$lastname" "$username" "$email" "$age" "$salary"
    done < "$file"
}

# Call main function with all arguments
main "$@"
