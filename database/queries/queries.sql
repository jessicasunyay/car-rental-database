CONNECT TO COMP421;

-- Find the names and IDs of renters who have rented cars that belong
-- to at least two different branches and also how many distinct branches they
-- have rented from (The point of this query is to identify customers who use the
-- service across different locations)
--1
WITH RenterBranches AS (
	SELECT re.renter_id,re.r_name,c.branch_id
	FROM Renter re
		JOIN Rental r ON r.renter_id = re.renter_id
		JOIN Car c ON c.license_plate_no = r.license_plate_no
		GROUP BY re.renter_id,re.r_name,c.branch_id
	)
SELECT renter_id,r_name,
COUNT(branch_id) AS branches_used
FROM RenterBranches
GROUP BY renter_id,r_name
HAVING COUNT(branch_id) > 1;




-- Find the license plate, model name, and manufacturer of every
-- car that has been both rented out at least once AND has had at least one repair.
--2
SELECT c.license_plate_no,cm.model_name,cm.manufacturer
FROM Car c
	JOIN Rental r ON r.license_plate_no = c.license_plate_no
	JOIN Car_Model cm ON cm.model_name = c.model_name
INTERSECT
SELECT c.license_plate_no,cm.model_name,cm.manufacturer
FROM Car c
	JOIN Repair rp ON rp.license_plate_no = c.license_plate_no
    	JOIN Car_Model cm ON cm.model_name = c.model_name;



--For each branch, find the mechanic(could be mutiple mechanics if there is a tie) who has
--performed the most repairs at that branch,also show their employee ID,the branch ID, name, and total number of repairs.
--3

SELECT e.employee_id,e.branch_id,e.e_name,COUNT(rp.repair_id) AS total_repairs
FROM Employee e
	JOIN Mechanic m ON m.employee_id = e.employee_id AND m.branch_id = e.branch_id
        JOIN Repair rp ON rp.employee_id = e.employee_id AND rp.branch_id = e.branch_id
GROUP BY e.employee_id,e.branch_id,e.e_name
HAVING COUNT(rp.repair_id) >= ALL (
	SELECT COUNT(rp2.repair_id)
        FROM Mechanic m2
        	JOIN Repair rp2 ON rp2.employee_id = m2.employee_id AND rp2.branch_id = m2.branch_id
    		WHERE m2.branch_id = e.branch_id
    		GROUP BY m2.employee_id,m2.branch_id
);


-- list employees either a manager or mechanic and rank them within their role by how many actions they handled
--4
WITH EmployeeRoleAction AS (
    SELECT
        e.employee_id,
        e.e_name,
        'Manager' AS role,
        COUNT(f.rental_id) AS num_actions
    FROM Employee e
    JOIN Manager m
        ON e.employee_id = m.employee_id
        AND e.branch_id = m.branch_id
    JOIN Fines f
        ON m.employee_id = f.employee_id
        AND m.branch_id = f.branch_id
    GROUP BY e.employee_id, e.e_name
    UNION
    SELECT
        e.employee_id,
        e.e_name,
        'Mechanic' AS role,
        COUNT(r.repair_id) AS num_actions
    FROM Employee e
    JOIN Mechanic m
        ON e.employee_id = m.employee_id
        AND e.branch_id = m.branch_id
    JOIN Repair r
        ON m.employee_id = r.employee_id
        AND m.branch_id = r.branch_id
    GROUP BY e.employee_id, e.e_name
)
SELECT
    employee_id,
    e_name,
    role,
    num_actions,
    RANK () OVER (
        PARTITION BY role
        ORDER BY num_actions DESC
    ) AS role_rank
FROM EmployeeRoleAction
ORDER BY role, role_rank, employee_id;

-- find renters who have rented cars from more than one branch
--5
SELECT
    re.renter_id,
    re.r_name,
    COUNT(DISTINCT r.branch_id) AS num_branches
FROM Renter re
JOIN Rental r ON re.renter_id = r.renter_id
JOIN Company_Branch b on r.branch_id = b.branch_id
GROUP BY re.renter_id, re.r_name
HAVING COUNT (DISTINCT r.branch_id) > 1;

-- find branches whose total rental revenue is above the average branch revenue
--6
SELECT
    b.branch_id,
    b.branch_name,
    SUM(r.total_cost) AS total_revenue
FROM Company_Branch b
JOIN Rental r ON b.branch_id = r.branch_id
JOIN Manager m ON r.employee_id = m.employee_id
            AND r.branch_id = m.branch_id
GROUP BY b.branch_id, b.branch_name
HAVING SUM(r.total_cost) >
    (SELECT AVG(branch_revenue)
    FROM
        (SELECT SUM(total_cost) AS branch_revenue
        FROM Rental
        GROUP BY branch_id)
    );

--7
-- list all cars and show the number of repairs each car has had
SELECT
    c.license_plate_no,
    m.model_name,
    COALESCE(COUNT(r.repair_id), 0) AS num_repairs
FROM Car c
JOIN Car_Model m
    ON c.model_name = m.model_name
LEFT JOIN Repair r
    ON c.license_plate_no = r.license_plate_no
GROUP BY c.license_plate_no, m.model_name
ORDER BY num_repairs DESC;


--For each car in the system, show its license plate, model name, the branch
--that it belongs to, and how many repairs it has had (including cars with zero repairs) 
--8
SELECT c.license_plate_no,m.model_name,cb.branch_name, 
	COALESCE(COUNT(r.repair_id),0) AS num_repairs
FROM Car c
	JOIN Car_Model m ON c.model_name = m.model_name
        JOIN Company_Branch cb ON cb.branch_id = c.branch_id
        LEFT JOIN Repair r ON c.license_plate_no = r.license_plate_no
GROUP BY c.license_plate_no,m.model_name,cb.branch_name
ORDER BY num_repairs DESC;


--For each car with a base rental cost that is above $50,show its license plate,base cost,model name, 
-- the branch name, and number of repairs (only for cars that have had at least one repair)
--and the results are ordered by most repairs first
--9
SELECT c.license_plate_no,m.model_name,m.base_cost, cb.branch_name,
	COALESCE(COUNT(r.repair_id),0) AS num_repairs
FROM Car c
	JOIN Car_Model m ON c.model_name = m.model_name
        JOIN Company_Branch cb ON cb.branch_id = c.branch_id
        LEFT JOIN Repair r ON c.license_plate_no = r.license_plate_no
WHERE m.base_cost > 50
GROUP BY c.license_plate_no,m.model_name,cb.branch_name,m.base_cost
HAVING COALESCE(COUNT(r.repair_id),0) >= 1
ORDER BY num_repairs DESC;



-- complex query: find the most loyal customers
WITH RenterActivity AS (
    SELECT
        re.renter_id,
        re.r_name,
        COUNT(r.rental_id) AS num_rentals,
        COUNT(DISTINCT c.branch_id) AS num_branches,
        COUNT(DISTINCT c.model_name) AS num_models
    FROM Renter re
    JOIN Rental r
        ON re.renter_id = r.renter_id
    Join Car c
        ON r.license_plate_no = c.license_plate_no
    GROUP BY re.renter_id, re.r_name
)
SELECT
    renter_id,
    r_name,
    num_rentals,
    num_branches,
    num_models,
    RANK() OVER(
        ORDER BY num_rentals DESC, num_branches DESC, num_models DESC
    ) AS activity_rank
FROM RenterActivity
ORDER BY activity_rank, renter_id;



-- complex query: find the most loyal customers
WITH RenterActivity AS (
    SELECT
        re.renter_id,
        re.r_name,
        COUNT(r.rental_id) AS num_rentals,
        COUNT(DISTINCT c.branch_id) AS num_branches,
        COUNT(DISTINCT c.model_name) AS num_models,
	SUM(DAYS(r.end_date) - DAYS(r.start_date)) AS total_days_rented,
	MIN(r.start_date) AS first_rental,
	MAX(r.end_date) AS last_rental
    FROM Renter re
    JOIN Rental r
        ON re.renter_id = r.renter_id
    Join Car c
        ON r.license_plate_no = c.license_plate_no
    GROUP BY re.renter_id, re.r_name
    HAVING COUNT(r.rental_id) >= 2
	AND COUNT( DISTINCT c.branch_id) > 1
	AND COUNT(DISTINCT c.model_name) > 1
),
RenterFines AS (
	SELECT r.renter_id,
        COUNT(f.rental_id) AS num_fines
    	FROM Rental r
        LEFT JOIN Fines f ON f.rental_id = r.rental_id
    	GROUP BY r.renter_id
)
SELECT
    ra.renter_id,
    ra.r_name,
    ra.num_rentals,
    ra.num_branches,
    ra.num_models,
    ra.total_days_rented,
    ra.first_rental,
    ra.last_rental,
    rf.num_fines,
    RANK() OVER(
        ORDER BY (ra.num_rentals - rf.num_fines) DESC, ra.num_branches DESC, ra.num_models DESC
    ) AS activity_rank
FROM RenterActivity ra
JOIN RenterFines rf ON rf.renter_id = ra.renter_id
ORDER BY activity_rank, ra.renter_id;

EXPORT TO rentals_per_month.csv OF DEL
MODIFIED BY NOCHARDEL
SELECT
    YEAR(start_date) AS yr,
    MONTH(start_date) AS mn,
    COUNT(*) AS num_rentals
FROM Rental
GROUP BY
    YEAR(start_date),
    MONTH(start_date)
ORDER BY yr, mn;

CREATE INDEX idx_repair_emp_branch_plate ON Repair(employee_id, branch_id, license_plate_no);


EXPORT TO rentals_per_month.csv OF DEL
MODIFIED BY NOCHARDEL
SELECT
    VARCHAR_FORMAT(start_date, 'YYYY-MM') AS rental_month,
    COUNT(*) AS num_rentals
FROM Rental
GROUP BY
    VARCHAR_FORMAT(start_date, 'YYYY-MM')
ORDER BY rental_month;

TERMINATE;
