import java.sql.*;
import java.util.Scanner;
import java.util.Map;
import java.util.HashMap;

class simpleJDBC {
    public static void main(String[] args) {
        String url = "jdbc:db2://winter2026-comp421.cs.mcgill.ca:50000/comp421";
        String your_userid = "cs421g01";
        String your_password = "group1rocks";

        Connection con = null;
        Scanner scanner = new Scanner(System.in);

        try {
            DriverManager.registerDriver(new com.ibm.db2.jcc.DB2Driver());

            if (your_userid == null && (your_userid = System.getenv("SOCSUSER")) == null) {
                System.err.println("Error!! do not have a user id to connect to the database!");
                System.exit(1);
            }

            if (your_password == null && (your_password = System.getenv("SOCSPASSWD")) == null) {
                System.err.println("Error!! do not have a password to connect to the database!");
                System.exit(1);
            }

            con = DriverManager.getConnection(url, your_userid, your_password);

            boolean running = true;

            while (running) {
                System.out.println();
                System.out.println("===== Car Rental Main Menu =====");
                System.out.println("1. Look up renter / Add new renter if renter not found");
                System.out.println("2. Issue Fines");
                System.out.println("3. View cars at a branch");
                System.out.println("4. Create a rental");
                System.out.println("5. Look up renters of frequently repaired cars");
                System.out.println("6. Quit");
                System.out.print("Please enter your option: ");

                String choice = scanner.nextLine();

                switch (choice) {
                    case "1":
                        lookUpRenter(con, scanner);
                        break;
                    case "2":
			issueFine(con, scanner);
                        break;
                    case "3":
                        viewCarsAtBranch(con, scanner);
                        break;
                    case "4":
                        createRental(con, scanner);
                        break;
                    case "5":
                        carsWithFrequentRepairs(con, scanner);
                        break;
                    case "6":
                        running = false;
                        System.out.println("Thank you for using our system!");
                        break;
                    default:
                        System.out.println("Invalid option. Please try again.");
                }
            }

        } catch (SQLException e) {
            System.out.println("Database error:");
            System.out.println("Code: " + e.getErrorCode() + " SQLState: " + e.getSQLState());
            System.out.println(e.getMessage());
        } catch (Exception e) {
            System.out.println("Unexpected error: " + e.getMessage());
        } finally {
            try {
                if (con != null) {
                    con.close();
                }
            } catch (SQLException e) {
                System.out.println("Error closing connection: " + e.getMessage());
            }
            scanner.close();
        }
    }

    static void addRenter(Connection con, Scanner scanner, int renterId){
	try {
            System.out.print("Enter renter name: ");
       	    String name = scanner.nextLine();

            System.out.print("Enter address: ");
            String address = scanner.nextLine();

            System.out.print("Enter license number: ");
            String licenseNo = scanner.nextLine();

            String sql = "INSERT INTO Renter (renter_id, r_name, address, license_no) VALUES (?, ?, ?, ?)";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, renterId);
                ps.setString(2, name);
                ps.setString(3, address);
                ps.setString(4, licenseNo);

                int rows = ps.executeUpdate();
                System.out.println(rows + " renter added successfully.");
            }  

        } catch (Exception e) {
            System.out.println("Error in addRenter: " + e.getMessage());
        } 
    }


    static void lookUpRenter(Connection con, Scanner scanner) {
        System.out.print("Enter renter ID: ");
        String renterId = scanner.nextLine();

        String sql = "SELECT renter_id, r_name, address, license_no FROM Renter WHERE renter_id = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, Integer.parseInt(renterId));
            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                System.out.println("No renter found.");
                System.out.println("Would you like to add a renter with this ID? (y/n): ");
		String response = scanner.nextLine();
		if (response.equals("y")){
		    addRenter(con, scanner, Integer.parseInt(renterId));
            	}
		return;
	    }

            do {
                System.out.println("Renter ID: " + rs.getInt("renter_id"));
                System.out.println("Name: " + rs.getString("r_name"));
                System.out.println("Address: " + rs.getString("address"));
                System.out.println("License No: " + rs.getString("license_no"));
            } while (rs.next());

        } catch (Exception e) {
            System.out.println("Error in lookUpRenter: " + e.getMessage());
        }
    }
    
    static void viewCarsAtBranch(Connection con, Scanner scanner) {
   	 System.out.print("Enter branch ID: ");
   	 String branchIdInput = scanner.nextLine();

   	 String checkBranchSQL = "SELECT branch_name, location FROM Company_Branch WHERE branch_id = ?";
	 try (PreparedStatement checkPs = con.prepareStatement(checkBranchSQL)) {
            int branchId = Integer.parseInt(branchIdInput);

            checkPs.setInt(1, branchId);
            ResultSet branchRs = checkPs.executeQuery();

            if (!branchRs.next()) {
                System.out.println("Branch not found.");
                return;
            } 

            String branchName = branchRs.getString("branch_name");
            String location = branchRs.getString("location");

            System.out.println("\nBranch: " + branchName);
            System.out.println("Location: " + location);

            System.out.println("\nChoose a filter option:");
            System.out.println("1. Show all cars");
            System.out.println("2. Filter by model name");
            System.out.println("3. Filter by maximum mileage");
            System.out.println("4. Filter by model name and maximum mileage");
            System.out.print("Enter your choice: ");

            String filterChoice = scanner.nextLine();
	    String sql = "";
	    PreparedStatement carPs = null;

            switch (filterChoice) {
                case "1":
		    sql = "SELECT c.license_plate_no, c.mileage, c.model_name, cm.manufacturer " +
                          "FROM Car c JOIN Car_Model cm ON c.model_name = cm.model_name " +
                          "WHERE c.branch_id = ?";
                    carPs = con.prepareStatement(sql);
                    carPs.setInt(1, branchId);
                    break;

                case "2":
                    System.out.print("Enter model name: ");
                    String modelName = scanner.nextLine();

		    sql = "SELECT c.license_plate_no, c.mileage, c.model_name, cm.manufacturer " +
                          "FROM Car c JOIN Car_Model cm ON c.model_name = cm.model_name " +
                          "WHERE c.branch_id = ? AND c.model_name = ?";
                    carPs = con.prepareStatement(sql);
                    carPs.setInt(1, branchId);
                    carPs.setString(2, modelName);
                    break;

                case "3":
                    System.out.print("Enter maximum mileage: ");
                    int maxMileage = Integer.parseInt(scanner.nextLine());

		    sql = "SELECT c.license_plate_no, c.mileage, c.model_name, cm.manufacturer " +
                          "FROM Car c JOIN Car_Model cm ON c.model_name = cm.model_name " +
                          "WHERE c.branch_id = ? AND c.mileage <= ?";
                    carPs = con.prepareStatement(sql);
                    carPs.setInt(1, branchId);
                    carPs.setInt(2, maxMileage);
                    break;

                case "4":
                    System.out.print("Enter model name: ");
                    String modelNameBoth = scanner.nextLine();

                    System.out.print("Enter maximum mileage: ");
                    int maxMileageBoth = Integer.parseInt(scanner.nextLine());

		    sql = "SELECT c.license_plate_no, c.mileage, c.model_name, cm.manufacturer " +
                          "FROM Car c JOIN Car_Model cm ON c.model_name = cm.model_name " +
                          "WHERE c.branch_id = ? AND c.model_name = ? AND c.mileage <= ?";
                    carPs = con.prepareStatement(sql);
                    carPs.setInt(1, branchId);
                    carPs.setString(2, modelNameBoth);
                    carPs.setInt(3, maxMileageBoth);
                    break;

		default:
		    System.out.println("Invalid option.");
		    return;
             }

             try (PreparedStatement ps = carPs) {
                 ResultSet carRs = carPs.executeQuery();
                 boolean found = false;

                 System.out.println("\nFiltered Cars:");
                 System.out.println("-----------------------------------");

                 while (carRs.next()) {
                     found = true;
                     System.out.println("License Plate: " + carRs.getString("license_plate_no"));
                     System.out.println("Mileage: " + carRs.getInt("mileage"));
		     System.out.println("Manufacturer: " + carRs.getString("manufacturer"));
                     System.out.println("Model: " + carRs.getString("model_name"));
                     System.out.println("-----------------------------------");
                 }

                 if (!found) {
                     System.out.println("No cars found matching your criteria.");
                 }
             }

         } catch (Exception e) {
             System.out.println("Error in viewCarsAtBranch: " + e.getMessage());
         }
    }

    static void issueFine(Connection con, Scanner scanner) {
    	PreparedStatement checkManagerPs = null;
    	PreparedStatement checkRentalPs = null;
   	PreparedStatement checkFinePs = null;
    	PreparedStatement insertFinePs = null;
    	ResultSet managerRs = null;
    	ResultSet rentalRs = null;
    	ResultSet fineRs = null;

    	try {
            System.out.print("Enter your employee ID: ");
            int employeeId = Integer.parseInt(scanner.nextLine());

            System.out.print("Enter your branch ID: ");
            int branchId = Integer.parseInt(scanner.nextLine());

            // Step 1: check if this employee is a manager
            String checkManagerSQL =
            "SELECT * FROM Manager WHERE employee_id = ? AND branch_id = ?";

            checkManagerPs = con.prepareStatement(checkManagerSQL);
            checkManagerPs.setInt(1, employeeId);
            checkManagerPs.setInt(2, branchId);
            managerRs = checkManagerPs.executeQuery();

            if (!managerRs.next()) {
                System.out.println("Access denied: you are not a manager.");
                return;
            }

            // Step 2: ask which rental to fine
            System.out.print("Enter rental ID to fine: ");
            int rentalId = Integer.parseInt(scanner.nextLine());

            // Step 3: check rental exists
            String checkRentalSQL =
            "SELECT * FROM Rental WHERE rental_id = ?";

            checkRentalPs = con.prepareStatement(checkRentalSQL);
            checkRentalPs.setInt(1, rentalId);
            rentalRs = checkRentalPs.executeQuery();

            if (!rentalRs.next()) {
            	System.out.println("Error: rental ID does not exist.");
            return;
            }

            // Step 4: check whether rental already has a fine
            String checkFineSQL =
            "SELECT * FROM Fines WHERE rental_id = ?";

            checkFinePs = con.prepareStatement(checkFineSQL);
            checkFinePs.setInt(1, rentalId);
            fineRs = checkFinePs.executeQuery();

            if (fineRs.next()) {
            	System.out.println("Error: this rental has already been fined.");
            return;
            }

            // Step 5: collect fine details
            System.out.print("Enter fine amount: ");
            double amount = Double.parseDouble(scanner.nextLine());


            System.out.print("Enter fine description: ");
            String description = scanner.nextLine();

            String insertFineSQL =
            "INSERT INTO Fines (rental_id, employee_id, branch_id, amount, f_description) " +
            "VALUES (?, ?, ?, ?, ?)";

            insertFinePs = con.prepareStatement(insertFineSQL);
            insertFinePs.setInt(1, rentalId);
            insertFinePs.setInt(2, employeeId);
            insertFinePs.setInt(3, branchId);
            insertFinePs.setDouble(4, amount);
            insertFinePs.setString(5, description);

        int rows = insertFinePs.executeUpdate();

        if (rows > 0) {
            System.out.println("Fine issued successfully.");
        } else {
            System.out.println("Fine could not be issued.");
        }

    	} catch (Exception e) {
        System.out.println("Error in issueFine: " + e.getMessage());
        } finally {
        try {
            if (fineRs != null) fineRs.close();
        } catch (SQLException e) {
            System.out.println("Error closing fine result set: " + e.getMessage());
        }

        try {
            if (rentalRs != null) rentalRs.close();
        } catch (SQLException e) {
            System.out.println("Error closing rental result set: " + e.getMessage());
        }

        try {
            if (managerRs != null) managerRs.close();
        } catch (SQLException e) {
            System.out.println("Error closing manager result set: " + e.getMessage());
        }

        try {
            if (insertFinePs != null) insertFinePs.close();
        } catch (SQLException e) {
            System.out.println("Error closing insert fine statement: " + e.getMessage());
        }

        try {
            if (checkFinePs != null) checkFinePs.close();
        } catch (SQLException e) {
            System.out.println("Error closing check fine statement: " + e.getMessage());
        }

        try {
            if (checkRentalPs != null) checkRentalPs.close();
        } catch (SQLException e) {
            System.out.println("Error closing check rental statement: " + e.getMessage());
        }

        try {
            if (checkManagerPs != null) checkManagerPs.close();
        } catch (SQLException e) {
            System.out.println("Error closing check manager statement: " + e.getMessage());
          }
        }
    }
    static void carsWithFrequentRepairs(Connection con, Scanner scanner) {
    	String sql = "SELECT license_plate_no, COUNT(*) AS repair_count FROM Repair GROUP BY license_plate_no HAVING COUNT(*) >= 5";
    	
	try (PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
        	int index = 1;
        	Map<Integer, String> options = new HashMap<>();
		System.out.println("\nCars with 5 or more repairs:");
        	while (rs.next()) {
            		String plate = rs.getString("license_plate_no");
            		int count = rs.getInt("repair_count");
            		System.out.println(index + ". " + plate + " (" + count + " repairs)");
            		options.put(index, plate);
            		index++;
        	}

       		if (options.isEmpty()) {
        	    System.out.println("No cars found.");
        	    return;
        	}

        	System.out.print("Select an option to view renters: ");
        	int choice = Integer.parseInt(scanner.nextLine());

        	if (!options.containsKey(choice)) {
            		System.out.println("Invalid selection.");
            		return;
        	}

        	String selectedPlate = options.get(choice);
        	showRentersForCar(con, selectedPlate);
    	} catch (Exception e) {
        	System.out.println("Error in carsWithFrequentRepairs: " + e.getMessage());
    	}
    }
    static void showRentersForCar(Connection con, String licensePlate) {
    	String sql = "SELECT r.renter_id, r.r_name, rt.start_date, rt.end_date FROM Rental rt JOIN Renter r ON rt.renter_id = r.renter_id WHERE rt.license_plate_no = ?";

    	try (PreparedStatement ps = con.prepareStatement(sql)) {
        	ps.setString(1, licensePlate);
        	ResultSet rs = ps.executeQuery();
		System.out.println("\nRenters who rented car " + licensePlate + ":");
        	boolean found = false;

		while (rs.next()) {
            found = true;
            int renterId = rs.getInt("renter_id");
            String name = rs.getString("r_name");
            Date startDate = rs.getDate("start_date");
            Date endDate = rs.getDate("end_date");

            System.out.println("Renter ID: " + renterId + ", Renter Name: " + name + ", Rental Date: " + startDate + " -> " + endDate);
        }

        if (!found) {
            System.out.println("No renters found.");
        }
    	} catch (Exception e) {
        	System.out.println("Error in showRentersForCar: " + e.getMessage());
    	}
   }
    static void createRental(Connection con, Scanner scanner) {
    try {
        // check if manager
        System.out.print("Enter branch ID: ");
        int branchId = Integer.parseInt(scanner.nextLine());

        System.out.print("Enter your employee ID: ");
        int employeeId = Integer.parseInt(scanner.nextLine());

        String mgrCheckSQL = "SELECT * FROM Manager WHERE employee_id = ? AND branch_id = ?";
        try (PreparedStatement mgrPs = con.prepareStatement(mgrCheckSQL)) {
            mgrPs.setInt(1, employeeId);
            mgrPs.setInt(2, branchId);
            ResultSet mgrRs = mgrPs.executeQuery();
            if (!mgrRs.next()) {
                System.out.println("You are not authorized. Only managers can create rentals.");
                return;
            }
        }

        // prompt rental details
	int rentalId;
        while (true) {
            System.out.print("Enter rental ID: ");
            rentalId = Integer.parseInt(scanner.nextLine());

            String idCheckSQL = "SELECT rental_id FROM Rental WHERE rental_id = ?";
            try (PreparedStatement idCheckPs = con.prepareStatement(idCheckSQL)) {
                idCheckPs.setInt(1, rentalId);
                ResultSet idCheckRs = idCheckPs.executeQuery();
                if (!idCheckRs.next()) break; // ID does not exist
		}

            System.out.println("Rental ID already exists. Please choose a different one.");
        }

	//prompt renter id
	System.out.print("Enter renter ID: ");
        int renterId = Integer.parseInt(scanner.nextLine());

        // check valid renter id
        String renterCheckSQL = "SELECT * FROM Renter WHERE renter_id = ?";
        try (PreparedStatement renterPs = con.prepareStatement(renterCheckSQL)) {
            renterPs.setInt(1, renterId);
            ResultSet renterRs = renterPs.executeQuery();
            if (!renterRs.next()) {
                System.out.println("Renter ID not found.");
                return;
            }
        }

        System.out.print("Enter license plate number of the car: ");
        String licensePlate = scanner.nextLine();

	// check car exists
	String carExistsSQL = "SELECT * FROM Car WHERE license_plate_no = ?";
	try (PreparedStatement carExistsPs = con.prepareStatement(carExistsSQL)) {
		carExistsPs.setString(1, licensePlate);
    		ResultSet carExistsRs = carExistsPs.executeQuery();
    		if (!carExistsRs.next()) {
        		System.out.println("Car does not exist in the system.");
        		return;
    		}
	}
        // check car is at same branch as manager
        String carCheckSQL = "SELECT * FROM Car WHERE license_plate_no = ? AND branch_id = ?";
        try (PreparedStatement carPs = con.prepareStatement(carCheckSQL)) {
            carPs.setString(1, licensePlate);
            carPs.setInt(2, branchId);
            ResultSet carRs = carPs.executeQuery();
            if (!carRs.next()) {
                System.out.println("Car is not located in your branch.");
                return;
	    }
        }

        // prompt dates
        System.out.print("Enter start date (YYYY-MM-DD): ");
        String startDate = scanner.nextLine();
        System.out.print("Enter end date (YYYY-MM-DD): ");
        String endDate = scanner.nextLine();

        // check availability
        String availSQL = "SELECT * FROM Rental WHERE license_plate_no = ? AND NOT (end_date < ? OR start_date > ?)";
        try (PreparedStatement availPs = con.prepareStatement(availSQL)) {
            availPs.setString(1, licensePlate);
            availPs.setDate(2, Date.valueOf(startDate));
            availPs.setDate(3, Date.valueOf(endDate));
            ResultSet availRs = availPs.executeQuery();
            if (availRs.next()) {
                System.out.println("Car is not available for the selected period.");
                return;
            }
        }

        // prompt insurance
        System.out.print("Enter insurance ID (or leave blank for none): ");
        String insuranceInput = scanner.nextLine();
        Integer insuranceId = null;
        if (!insuranceInput.isBlank()) {
            insuranceId = Integer.parseInt(insuranceInput);
            // check insurance
            String insCheckSQL = "SELECT * FROM Insurance WHERE insurance_id = ?";
            try (PreparedStatement insPs = con.prepareStatement(insCheckSQL)) {
                insPs.setInt(1, insuranceId);
                ResultSet insRs = insPs.executeQuery();
                if (!insRs.next()) {
                    System.out.println("Insurance ID not found.");
                    return;
                }
            }
        }

        // insert the rental record
        String insertSQL = "INSERT INTO Rental (rental_id, start_date, end_date, total_cost, license_plate_no, renter_id, insurance_id, employee_id, branch_id) VALUES (?,?,?,NULL,?,?,?,?,?)";
	try (PreparedStatement insertPs = con.prepareStatement(insertSQL)) {
            insertPs.setInt(1,rentalId);
	    insertPs.setDate(2, Date.valueOf(startDate));
            insertPs.setDate(3, Date.valueOf(endDate));
            insertPs.setString(4, licensePlate);
            insertPs.setInt(5, renterId);
            if (insuranceId != null) {
                insertPs.setInt(6, insuranceId);
            } else {
                insertPs.setNull(6, java.sql.Types.INTEGER);
            }
            insertPs.setInt(7, employeeId);
            insertPs.setInt(8, branchId);

            int rows = insertPs.executeUpdate();
            if (rows > 0) {
                System.out.println("Rental successfully created.");
            } else {
                System.out.println("Failed to create rental.");
                return;
            }
        }

        // ask if user wants to compute total cost now (mod 1 from P2)
        System.out.print("Do you want to compute total cost for this and all other pending rentals now? (y/n): ");
        String computeChoice = scanner.nextLine();
        if (computeChoice.equalsIgnoreCase("y")) {
            fillTotalCost(con);
        }

    } catch (Exception e) {
        System.out.println("Error in createRental: " + e.getMessage());
    }
}
static void fillTotalCost(Connection con) { //mod1 from P2
    String updateSQL = 
        "UPDATE Rental R " +
        "SET total_cost = (" +
        "    SELECT (CM.base_cost + COALESCE(I.cost_per_day, 0)) * (DAYS(R.end_date) - DAYS(R.start_date) + 1) " +
        "    FROM Car C " +
        "    JOIN Car_Model CM ON C.model_name = CM.model_name " +
        "    LEFT JOIN Insurance I ON R.insurance_id = I.insurance_id " +
        "    WHERE C.license_plate_no = R.license_plate_no" +
        ") " +
        "WHERE R.total_cost IS NULL";

    try (PreparedStatement ps = con.prepareStatement(updateSQL)) {
        int updated = ps.executeUpdate();
        System.out.println("Updated total_cost for " + updated + " rental(s).");
    } catch (Exception e) {
        System.out.println("Error updating total cost: " + e.getMessage());
    }
}

}
