USE campus_event_management;

-- P-1: Register Student for Event (Handles team or creates one)
DELIMITER $$
CREATE PROCEDURE RegisterStudentForEvent(
    IN student_id_in INT, 
    IN event_id_in INT,
    IN team_name_in VARCHAR(100),
    IN reg_for_in VARCHAR(100),
    IN payment_status_in VARCHAR(50)
)
BEGIN
    DECLARE pteam_id_var INT;

    SELECT pt.PTeam_ID INTO pteam_id_var
    FROM Participating_Team pt
    JOIN PTeam_Members ptm ON pt.PTeam_ID = ptm.PTeam_ID
    WHERE pt.Event_ID = event_id_in AND ptm.Student_ID = student_id_in
    LIMIT 1;

    IF pteam_id_var IS NULL THEN
        INSERT INTO Participating_Team (Team_Name, Event_ID)
        VALUES (team_name_in, event_id_in);
        SET pteam_id_var = LAST_INSERT_ID();

        INSERT INTO PTeam_Members (PTeam_ID, Student_ID)
        VALUES (pteam_id_var, student_id_in);
    END IF;

    INSERT INTO Registrations (Reg_For, Reg_Date, Payment_Status, Student_ID, PTeam_ID) 
    VALUES (reg_for_in, CURDATE(), payment_status_in, student_id_in, pteam_id_var);

    SELECT 'Registration successful' AS Status, LAST_INSERT_ID() AS Registration_ID;
END$$
DELIMITER ;

-- P-2: Process Cancellation
DELIMITER $$
CREATE PROCEDURE ProcessCancellation(
    IN reg_id_in INT,
    IN reason_in TEXT,
    IN team_cancel BOOLEAN
)
BEGIN
    DECLARE student_id_var INT;
    DECLARE team_id_var INT;

    -- fetch student & team
    SELECT r.Student_ID, pt.PTeam_ID
    INTO student_id_var, team_id_var
    FROM Registrations r
    LEFT JOIN PTeam_Members ptm ON r.Student_ID = ptm.Student_ID AND r.PTeam_ID = ptm.PTeam_ID
    LEFT JOIN Participating_Team pt ON ptm.PTeam_ID = pt.PTeam_ID
    WHERE r.Registration_ID = reg_id_in;

    IF student_id_var IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid or already cancelled Registration ID.';
    END IF;

    IF team_id_var IS NOT NULL AND team_cancel THEN
        -- cancel all team members
        INSERT INTO Cancellations(Reg_ID, Cancelled_Date, Reason)
        SELECT Registration_ID, CURDATE(), CONCAT('Team Cancellation: ', reason_in)
        FROM Registrations
        WHERE PTeam_ID = team_id_var AND Payment_Status != 'Cancelled';

        UPDATE Registrations
        SET Payment_Status = 'Cancelled'
        WHERE PTeam_ID = team_id_var AND Payment_Status != 'Cancelled';

        SELECT CONCAT('Team cancellation successfully processed for Team ID ', team_id_var) AS Status;
    ELSE
        -- cancel only this registration
        INSERT INTO Cancellations(Reg_ID, Cancelled_Date, Reason)
        VALUES (reg_id_in, CURDATE(), reason_in);

        UPDATE Registrations
        SET Payment_Status = 'Cancelled'
        WHERE Registration_ID = reg_id_in;

        SELECT CONCAT('Solo cancellation successfully processed for Registration ID ', reg_id_in) AS Status;
    END IF;
END$$
DELIMITER ;

drop procedure ProcessCancellation;
-- P-3: Allocate Resource to Event
DELIMITER $$
CREATE PROCEDURE AllocateResourceToEvent(
    IN event_id_in INT, 
    IN resource_name_in VARCHAR(100),
    IN resource_type_in VARCHAR(50),
    IN quantity_in INT
)
BEGIN
    DECLARE existing_resource_id INT;

    SELECT Resource_ID INTO existing_resource_id
    FROM Resources
    WHERE Event_ID = event_id_in AND Resource_Name = resource_name_in
    LIMIT 1;

    IF existing_resource_id IS NOT NULL THEN
        UPDATE Resources
        SET Quantity = Quantity + quantity_in
        WHERE Resource_ID = existing_resource_id;
        SELECT 'Resource quantity updated' AS Status;
    ELSE
        INSERT INTO Resources (Resource_Name, Resource_Type, Quantity, Event_ID)
        VALUES (resource_name_in, resource_type_in, quantity_in, event_id_in);
        SELECT 'New resource allocated' AS Status;
    END IF;
END$$
DELIMITER ;

-- P-4: Update Faculty Incharge
DELIMITER $$
CREATE PROCEDURE UpdateFacultyIncharge(
    IN event_id_in INT, 
    IN new_faculty_id_in INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Faculty WHERE Faculty_ID = new_faculty_id_in) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'New Faculty ID does not exist.';
    END IF;

    UPDATE Event
    SET Faculty_ID = new_faculty_id_in
    WHERE Event_ID = event_id_in;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Event not found or new Faculty ID is the same.';
    ELSE
        SELECT CONCAT('Faculty in charge updated for Event ID ', event_id_in) AS Status;
    END IF;
END$$
DELIMITER ;

-- P-5: Generate Event Report
DELIMITER $$
CREATE PROCEDURE GenerateEventReport(IN event_id_in INT)
BEGIN
    SELECT e.Event_ID, e.Event_Name, e.Date, e.Event_Type, e.Budget, v.Venue_Name, v.Capacity, c.Club_Name AS Organizing_Club, f.Name AS Faculty_Incharge,
        GetTotalRegistrations(e.Event_ID) AS Total_Registrations, GetAvgEventRating(e.Event_ID) AS Avg_Rating,
        (SELECT COUNT(*) FROM Grievances g WHERE g.Event_ID = e.Event_ID) AS Total_Grievances,
        GROUP_CONCAT(r.Resource_Name, ' (Qty: ', r.Quantity, ')' SEPARATOR ' | ') AS Resources_Used
    FROM Event e
    JOIN Venue v ON e.Venue_ID = v.Venue_ID
    JOIN Clubs c ON e.Club_ID = c.Club_ID
    JOIN Faculty f ON e.Faculty_ID = f.Faculty_ID
    LEFT JOIN Resources r ON e.Event_ID = r.Event_ID
    WHERE e.Event_ID = event_id_in
    GROUP BY e.Event_ID;
END$$
DELIMITER ;

-- P-6: Update Team Budget
DELIMITER $$
CREATE PROCEDURE UpdateTeamBudget(
    IN event_id_in INT, 
    IN new_budget_in DECIMAL(12, 2)
)
BEGIN
    UPDATE Event
    SET Budget = new_budget_in
    WHERE Event_ID = event_id_in;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Event not found.';
    ELSE
        SELECT CONCAT('Budget updated to ', new_budget_in, ' for Event ID ', event_id_in) AS Status;
    END IF;
END$$
DELIMITER ;

-- P-7: Get Events by Club and Type
DELIMITER $$
CREATE PROCEDURE GetEventsByClubAndType(
    IN club_id_in INT, 
    IN event_type_in VARCHAR(50)
)
BEGIN
    SELECT e.Event_ID, e.Event_Name, e.Date, e.Start_Time, v.Venue_Name, f.Name AS Faculty_Incharge
    FROM Event e
    JOIN Venue v ON e.Venue_ID = v.Venue_ID
    JOIN Faculty f ON e.Faculty_ID = f.Faculty_ID
    WHERE e.Club_ID = club_id_in AND e.Event_Type = event_type_in
    ORDER BY e.Date, e.Start_Time;
END$$
DELIMITER ;

-- P-8: Update Event Venue
DELIMITER $$
CREATE PROCEDURE UpdateEventVenue(
    IN event_id_in INT, 
    IN new_venue_id_in INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Venue WHERE Venue_ID = new_venue_id_in) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'New Venue ID does not exist.';
    END IF;

    UPDATE Event
    SET Venue_ID = new_venue_id_in
    WHERE Event_ID = event_id_in;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Event not found.';
    ELSE
        SELECT CONCAT('Venue updated for Event ID ', event_id_in) AS Status;
    END IF;
END$$
DELIMITER ;

-- P-9: Assign Organising Team Member
DELIMITER $$
CREATE PROCEDURE AssignOrganisingTeamMember(
    IN oteam_id_in INT, 
    IN student_id_in INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Students WHERE Student_ID = student_id_in) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student ID does not exist.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Organising_Team WHERE OTeam_ID = oteam_id_in) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Organising Team ID does not exist.';
    END IF;

    INSERT INTO OTeam_Members (OTeam_ID, Student_ID)
    VALUES (oteam_id_in, student_id_in);

    SELECT 'Student successfully added to Organising Team' AS Status;
END$$
DELIMITER ;

-- P-10: Get Events For Date
DELIMITER $$
CREATE PROCEDURE GetEventsForDate(IN event_date DATE)
BEGIN
    SELECT e.Event_ID, e.Event_Name, e.Event_Type, e.Start_Time, e.End_Time, v.Venue_Name, c.Club_Name
    FROM Event e
    JOIN Venue v ON e.Venue_ID = v.Venue_ID
    JOIN Clubs c ON e.Club_ID = c.Club_ID
    WHERE e.Date = event_date
    ORDER BY e.Start_Time;
END$$
DELIMITER ;

-- P-11: Get Future Events
DELIMITER $$
CREATE PROCEDURE GetFutureEvents()
BEGIN
    SELECT 
        e.Event_ID, 
        e.Event_Name, 
        e.Date, 
        v.Venue_Name AS Venue,
        f.Name AS Faculty_In_Charge
    FROM event e
    JOIN venue v ON e.Venue_ID = v.Venue_ID
    JOIN faculty f ON e.Faculty_ID = f.Faculty_ID
    WHERE e.Date >= CURDATE()
    ORDER BY e.Date ASC; 
END$$
DELIMITER ;

SELECT ROUTINE_NAME AS Procedure_Name, CREATED, LAST_ALTERED
FROM information_schema.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_SCHEMA = 'campus_event_management'
ORDER BY ROUTINE_NAME;

drop procedure GetFutureEvents;