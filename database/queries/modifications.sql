-- LEAVE this statement on. It is required to connect to your database.
CONNECT TO COMP421;

-- ====================================================================
-- Modification 1: Automated Rental Billing
-- Computes and populates total_cost for unbilled rentals based on 
-- vehicle base rates, daily insurance costs, and rental duration.
-- ====================================================================
UPDATE Rental R
SET total_cost = (
    SELECT 
        (CM.base_cost + I.cost_per_day) * (DAYS(R.end_date) - DAYS(R.start_date) + 1)
    FROM Car C
    JOIN Car_Model CM ON C.model_name = CM.model_name
    JOIN Insurance I ON R.insurance_id = I.insurance_id
    WHERE C.license_plate_no = R.license_plate_no
)
WHERE R.total_cost IS NULL;


-- ====================================================================
-- Modification 2: Performance-Based Mechanic Bonuses
-- Targets the Employee table to issue a 5% salary increase to all 
-- mechanics who completed 3 or more vehicle repairs in the last 30 days.
-- ====================================================================
UPDATE Employee
SET salary = salary * 1.05 
WHERE (employee_id, branch_id) IN (
    SELECT employee_id, branch_id
    FROM Repair
    WHERE date > CURRENT DATE - 30 DAYS
    GROUP BY employee_id, branch_id
    HAVING COUNT(repair_id) >= 3
);