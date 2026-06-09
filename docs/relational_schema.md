# Relational Schema

Below is the logical relational schema for the vehicle rental and maintenance tracking system.

- Primary keys are indicated in **bold**.
- Foreign keys are explicitly mapped beneath each relation.

---

### Relations & Constraints

- **Company_Branch** (**branch_id**, branch_name, location)
- **Car_Model** (**model_name**, manufacturer, base_cost)
- **Car** (**license_plate_no**, mileage, branch_id, model_name)
  - `branch_id` is a Foreign Key referencing `Company_Branch(branch_id)`
  - `model_name` is a Foreign Key referencing `Car_Model(model_name)`
- **Employee** (**employee_id**, **branch_id**, e_name, salary)
  - `branch_id` is a Foreign Key referencing `Company_Branch(branch_id)`
- **Mechanic** (**employee_id**, **branch_id**)
  - `(employee_id, branch_id)` is a composite Foreign Key referencing `Employee(employee_id, branch_id)`
- **Manager** (**employee_id**, **branch_id**)
  - `(employee_id, branch_id)` is a composite Foreign Key referencing `Employee(employee_id, branch_id)`
- **Insurance** (**insurance_id**, cost_per_day, i_description)
- **Renter** (**renter_id**, r_name, address, license_no)
- **Rental** (**rental_id**, start_date, end_date, total_cost, license_plate_no, renter_id, insurance_id, employee_id, branch_id)
  - `license_plate_no` is a Foreign Key referencing `Car(license_plate_no)`
  - `renter_id` is a Foreign Key referencing `Renter(renter_id)`
  - `insurance_id` is a Foreign Key referencing `Insurance(insurance_id)`
  - `(employee_id, branch_id)` is a composite Foreign Key referencing `Manager(employee_id, branch_id)`
- **Repair** (**repair_id**, date, r_description, license_plate_no, employee_id, branch_id)
  - `license_plate_no` is a Foreign Key referencing `Car(license_plate_no)`
  - `(employee_id, branch_id)` is a composite Foreign Key referencing `Mechanic(employee_id, branch_id)`
- **Fines** (**rental_id**, **employee_id**, **branch_id**, amount, f_description)
  - `rental_id` is a Foreign Key referencing `Rental(rental_id)`
  - `(employee_id, branch_id)` is a composite Foreign Key referencing `Manager(employee_id, branch_id)`
  - `branch_id` is a Foreign Key referencing `Company_Branch(branch_id)`
