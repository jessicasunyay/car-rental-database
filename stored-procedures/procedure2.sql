CONNECT TO COMP421@

CREATE OR REPLACE PROCEDURE flag_high_mileage_cars (
    IN mileage_threshold DECIMAL(10,2),
    IN days_since_repair INT,
    IN mechanic_emp_id INT,
    IN mechanic_branch_id INT
)
LANGUAGE SQL
BEGIN
    DECLARE v_plate VARCHAR(50);
    DECLARE v_branch_id INT;
    DECLARE done INT DEFAULT 0;
    DECLARE new_repair_id INT;
    DECLARE car_cursor CURSOR FOR
        SELECT c.license_plate_no, c.branch_id
        FROM Car c
        WHERE c.mileage > mileage_threshold
        AND c.license_plate_no NOT IN (
            SELECT r.license_plate_no
            FROM Repair r
            WHERE r.date > CURRENT DATE - days_since_repair DAYS
        );
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET done = 1;
    OPEN car_cursor;
    flag_loop: LOOP
        FETCH car_cursor INTO v_plate, v_branch_id;
        IF done = 1 THEN
            LEAVE flag_loop;
        END IF;
        SELECT COALESCE(MAX(repair_id), 0) + 1
        INTO new_repair_id
        FROM Repair;
        INSERT INTO Repair (repair_id, date, r_description, license_plate_no, employee_id, branch_id)
        VALUES (
            new_repair_id,
            CURRENT DATE,
            'Flagged for inspection: high mileage exceeded threshold',
            v_plate,
            mechanic_emp_id,
            mechanic_branch_id
        );
    END LOOP flag_loop;
    CLOSE car_cursor;
END@

TERMINATE@
