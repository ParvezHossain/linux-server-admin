CREATE DATABASE user_db;
USE user_db;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    username VARCHAR(50),
    email VARCHAR(100),
    age INT,
    salary DECIMAL(10, 2)
);