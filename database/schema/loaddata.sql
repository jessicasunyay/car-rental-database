-- loaddata.sql

CONNECT TO COMP421;

IMPORT FROM "car_rental_seed_data_bundle/Company_Branch.csv" OF DEL SKIPCOUNT 1 INSERT INTO Company_Branch;
IMPORT FROM "car_rental_seed_data_bundle/Car_Model.csv" OF DEL SKIPCOUNT 1 INSERT INTO Car_Model;
IMPORT FROM "car_rental_seed_data_bundle/Car.csv" OF DEL SKIPCOUNT 1 INSERT INTO Car;
IMPORT FROM "car_rental_seed_data_bundle/Employee.csv" OF DEL SKIPCOUNT 1 INSERT INTO Employee;
IMPORT FROM "car_rental_seed_data_bundle/Mechanic.csv" OF DEL SKIPCOUNT 1 INSERT INTO Mechanic;
IMPORT FROM "car_rental_seed_data_bundle/Manager.csv" OF DEL SKIPCOUNT 1 INSERT INTO Manager;
IMPORT FROM "car_rental_seed_data_bundle/Insurance.csv" OF DEL SKIPCOUNT 1 INSERT INTO Insurance;
IMPORT FROM "car_rental_seed_data_bundle/Renter.csv" OF DEL SKIPCOUNT 1 INSERT INTO Renter;
IMPORT FROM "car_rental_seed_data_bundle/Rental.csv" OF DEL SKIPCOUNT 1 INSERT INTO Rental;
IMPORT FROM "car_rental_seed_data_bundle/Repair.csv" OF DEL SKIPCOUNT 1 INSERT INTO Repair;
IMPORT FROM "car_rental_seed_data_bundle/Fines.csv" OF DEL SKIPCOUNT 1 INSERT INTO Fines;
TERMINATE;
