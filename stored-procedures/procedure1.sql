CONNECT TO COMP421@

CREATE OR REPLACE PROCEDURE fix_role_duplicate (IN role_to_keep VARCHAR(10))
LANGUAGE SQL
BEGIN
    DECLARE v_emp_id INT;
    DECLARE v_branch_id INT;
    DECLARE done INT DEFAULT 0;
    DECLARE role_cursor CURSOR FOR
        SELECT m.employee_id, m.branch_id
        FROM Mechanic m
        INNER JOIN Manager mn
        ON m.employee_id = mn.employee_id
        AND m.branch_id = mn.branch_id
        WHERE NOT EXISTS (
            SELECT 1 FROM Rental r
            WHERE r.employee_id = m.employee_id
            AND r.branch_id = m.branch_id
        )
        AND NOT EXISTS (
            SELECT 1 FROM Repair rp
            WHERE rp.employee_id = m.employee_id
            AND rp.branch_id = m.branch_id
        );
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET done = 1;
    OPEN role_cursor;
    fetch_loop: LOOP
        FETCH role_cursor INTO v_emp_id, v_branch_id;
        IF done = 1 THEN
            LEAVE fetch_loop;
        END IF;
        IF role_to_keep = 'Mechanic' THEN
            DELETE FROM Manager
            WHERE employee_id = v_emp_id AND branch_id = v_branch_id;
        ELSEIF role_to_keep = 'Manager' THEN
            DELETE FROM Mechanic
            WHERE employee_id = v_emp_id AND branch_id = v_branch_id;
        END IF;
    END LOOP fetch_loop;
    CLOSE role_cursor;
END@

TERMINATE@
