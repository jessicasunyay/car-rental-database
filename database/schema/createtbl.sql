-- LEAVE this statement on. It is required to connect to your database.
CONNECT TO COMP421;

-- Remember to put the create table ddls for the tables with foreign key references
--    ONLY AFTER the parent tables have already been created.


-- Company_Branch
CREATE TABLE Company_Branch (
    branch_id       INT             NOT NULL,
    branch_name     VARCHAR(50)    NOT NULL,
    location        VARCHAR(50)    NOT NULL,
    PRIMARY KEY (branch_id)
);

-- Car_Model
CREATE TABLE Car_Model (
    model_name      VARCHAR(50)    NOT NULL,
    manufacturer    VARCHAR(50)    NOT NULL,
    base_cost       DECIMAL(10,2)   CHECK (base_cost > 0),
    PRIMARY KEY (model_name)
);

-- Car
CREATE TABLE Car (
    license_plate_no    VARCHAR(50)     NOT NULL,
    mileage             DECIMAL(10,2)   CHECK (mileage >= 0),
    branch_id           INT             NOT NULL,
    model_name          VARCHAR(50)    NOT NULL,
    PRIMARY KEY (license_plate_no),
    CONSTRAINT fk_car_branch FOREIGN KEY (branch_id)
        REFERENCES Company_Branch(branch_id),
    CONSTRAINT fk_car_model FOREIGN KEY (model_name)
        REFERENCES Car_Model(model_name)
);

-- Employee
CREATE TABLE Employee (
    employee_id     INT             NOT NULL,
    branch_id       INT             NOT NULL,
    e_name          VARCHAR(50)    NOT NULL,
    salary          DECIMAL(10,2)   NOT NULL, 
    PRIMARY KEY (employee_id, branch_id),
    CONSTRAINT fk_employee_branch FOREIGN KEY (branch_id)
        REFERENCES Company_Branch(branch_id),
    CONSTRAINT chk_employee_min_salary CHECK (salary >= 31200.00)
);

-- Mechanic
-- PENDING CONSTRAINT: Cannot enforce that a Mechanic is not also a Manager at DB level
CREATE TABLE Mechanic (
    employee_id     INT     NOT NULL,
    branch_id       INT     NOT NULL,
    PRIMARY KEY (employee_id, branch_id),
    CONSTRAINT fk_mechanic_employee FOREIGN KEY (employee_id, branch_id)
        REFERENCES Employee(employee_id, branch_id)
);

-- Manager
-- PENDING CONSTRAINT: Cannot enforce that a Manager is not also a Mechanic at DB level
CREATE TABLE Manager (
    employee_id     INT     NOT NULL,
    branch_id       INT     NOT NULL,
    PRIMARY KEY (employee_id, branch_id),
    CONSTRAINT fk_manager_employee FOREIGN KEY (employee_id, branch_id)
        REFERENCES Employee(employee_id, branch_id)
);

-- Insurance
CREATE TABLE Insurance (
    insurance_id    INT             NOT NULL,
    cost_per_day    DECIMAL(10,2)   NOT NULL CHECK (cost_per_day > 0),
    i_description   VARCHAR(255),
    PRIMARY KEY (insurance_id)
);

-- Renter
CREATE TABLE Renter (
    renter_id       INT             NOT NULL,
    r_name          VARCHAR(100)    NOT NULL,
    address         VARCHAR(200)    NOT NULL,
    license_no      VARCHAR(50)     NOT NULL,
    PRIMARY KEY (renter_id)
);

-- Rental
CREATE TABLE Rental (
    rental_id           INT             NOT NULL,
    start_date          DATE            NOT NULL,
    end_date            DATE            NOT NULL,
    total_cost          DECIMAL(10,2)   CHECK (total_cost >= 0),
    license_plate_no    VARCHAR(20)     NOT NULL,
    renter_id           INT             NOT NULL,
    insurance_id        INT,
    employee_id         INT             NOT NULL,
    branch_id           INT             NOT NULL,
    PRIMARY KEY (rental_id),
    CONSTRAINT fk_rental_car FOREIGN KEY (license_plate_no)
        REFERENCES Car(license_plate_no),
    CONSTRAINT fk_rental_renter FOREIGN KEY (renter_id)
        REFERENCES Renter(renter_id),
    CONSTRAINT fk_rental_insurance FOREIGN KEY (insurance_id)
        REFERENCES Insurance(insurance_id),
    CONSTRAINT fk_rental_manager FOREIGN KEY (employee_id, branch_id)
        REFERENCES Manager(employee_id, branch_id),
    -- Add your check constraint right here!
    CONSTRAINT check_rental_dates CHECK (end_date >= start_date)
);

-- Repair
CREATE TABLE Repair (
    repair_id           INT             NOT NULL,
    date                DATE            NOT NULL,
    r_description       VARCHAR(255),
    license_plate_no    VARCHAR(20)     NOT NULL,
    employee_id         INT             NOT NULL,
    branch_id  INT             NOT NULL,
    PRIMARY KEY (repair_id),
    CONSTRAINT fk_repair_car FOREIGN KEY (license_plate_no)
        REFERENCES Car(license_plate_no),
    CONSTRAINT fk_repair_mechanic FOREIGN KEY (employee_id, branch_id)
        REFERENCES Mechanic(employee_id, branch_id)
);

-- Fines
CREATE TABLE Fines (
    rental_id       INT             NOT NULL,
    employee_id     INT             NOT NULL,
    branch_id       INT             NOT NULL,
    amount          DECIMAL(10,2)   NOT NULL CHECK (amount > 0),
    f_description   VARCHAR(255),
    PRIMARY KEY (rental_id, employee_id, branch_id),
    CONSTRAINT fk_fines_rental FOREIGN KEY (rental_id)
        REFERENCES Rental(rental_id),
    CONSTRAINT fk_fines_manager FOREIGN KEY (employee_id, branch_id)
        REFERENCES Manager(employee_id, branch_id),
    CONSTRAINT fk_fines_branch FOREIGN KEY (branch_id)
        REFERENCES Company_Branch(branch_id)
);

-- ====================================================================
-- PERFORMANCE TUNING: Secondary Indexes
-- Optimized for analytical lookups, range scans, and multi-table joins.
-- ====================================================================

-- Index 1: Optimizes frequent repair history lookups by vehicle
DROP INDEX idx_repair_car;
CREATE INDEX idx_repair_car ON Repair(license_plate_no);

-- Index 2: Speeds up recent repair filtering (e.g., the 30-day window check)
DROP INDEX idx_repair_date;
CREATE INDEX idx_repair_date ON Repair(date);

-- Index 3: Composite index optimizing joint customer-vehicle tracking patterns
DROP INDEX idx_rental_renter_plate;
CREATE INDEX idx_rental_renter_plate ON Rental(renter_id, license_plate_no);