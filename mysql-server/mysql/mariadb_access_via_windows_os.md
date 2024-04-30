README: Accessing MySQL/MariaDB Console on Windows
This section provides instructions on how to access the MySQL or MariaDB console on Windows and how to import a database.

Prerequisites
Ensure that MySQL or MariaDB is installed on your system.
Know the username and password to access MySQL/MariaDB.
Have administrative privileges to run commands in Command Prompt.
Step 1: Identify the MySQL/MariaDB Installation Path
Locate the installation path for MySQL or MariaDB. If you are using WAMP, the path is typically under the WAMP installation directory.

Example:

WAMP installation path for MySQL: C:\wamp64\bin\mysql\mysql8.2.0\bin
WAMP installation path for MariaDB: C:\wamp64\bin\mariadb\mariadb10.5.8\bin
Step 2: Open Command Prompt with Administrative Privileges
To access the MySQL/MariaDB console, you need to open Command Prompt with root/administrative privileges.

Press Windows + R, type cmd, then press Enter.
Right-click on the Command Prompt icon and select "Run as administrator".
Step 3: Navigate to the MySQL/MariaDB Installation Path
Use the cd command to navigate to the MySQL/MariaDB bin directory.

cmd
Copy code
cd C:\wamp64\bin\mysql\mysql8.2.0\bin
Replace the path with your specific installation path.

Step 4: Access the MySQL/MariaDB Console
To access the MySQL/MariaDB console, use the mysql command with the appropriate username and password:

cmd
Copy code
mysql -u <username> -p
Replace <username> with your MySQL/MariaDB username. You will be prompted for a password.

Step 5: Import a Database
To import an SQL file into a specific database, use the following command:

cmd
Copy code
mysql -u <username> -p <dbname> < [file_location]
<username>: Your MySQL/MariaDB username.
<dbname>: The name of the database into which you want to import the SQL file.
[file_location]: The full path to the SQL file you want to import.
Example of Importing a Database
If you want to import a database called my_database from an SQL file located at C:\data\backup.sql:

cmd
Copy code
mysql -u root -p my_database < C:\data\backup.sql
Notes
Ensure the path to the SQL file is correct.
Use proper permissions to avoid access issues.
If you encounter errors, check your MySQL/MariaDB logs for additional information.