-- LEAVE this statement on. It is required to connect to your database.
CONNECT TO COMP421;

-- ==========================================
-- VIEW 1: View1_EmployeeInfo
-- ==========================================
-- Drop the view first if it already exists to allow clean overwrites
DROP VIEW View1_EmployeeInfo;

CREATE VIEW View1_EmployeeInfo
AS
SELECT
    employee_id,
    branch_id,
    e_name          AS employee_name
FROM Employee;


-- ==========================================
-- VIEW 2: View2_RentalDetails
-- ==========================================
-- Drop the view first if it already exists to allow clean overwrites
DROP VIEW View2_RentalDetails;

CREATE VIEW View2_RentalDetails
AS
SELECT
    r.rental_id           AS rental_id,
    rt.r_name             AS customer_name,
    r.license_plate_no    AS car_license_plate,
    cm.manufacturer       AS car_manufacturer,
    c.model_name          AS car_model,
    cb.branch_name        AS rental_branch_name,
    r.start_date          AS rental_start_date,
    r.end_date            AS rental_end_date,
    cm.base_cost          AS car_base_cost,
    i.cost_per_day        AS insurance_cost_per_day,
    r.total_cost          AS total_rental_cost,
    cb.location           AS rental_branch_location
FROM Rental r
JOIN Renter rt
    ON r.renter_id = rt.renter_id
JOIN Car c
    ON r.license_plate_no = c.license_plate_no
JOIN Car_Model cm
    ON c.model_name = cm.model_name
JOIN Company_Branch cb
    ON r.branch_id = cb.branch_id
LEFT JOIN Insurance i
    ON r.insurance_id = i.insurance_id;