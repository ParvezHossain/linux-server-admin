DELIMITER //

CREATE PROCEDURE write_log(IN log_message TEXT)
BEGIN
    INSERT INTO logs (log_time, message) VALUES (NOW(), log_message);
END//

DELIMITER ;