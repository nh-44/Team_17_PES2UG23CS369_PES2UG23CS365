USE campus_event_management;

-- F-1: Get Total Registrations
DELIMITER $$
CREATE FUNCTION GetTotalRegistrations(event_id_in INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE reg_count INT;
    SELECT COUNT(r.Registration_ID) INTO reg_count
    FROM Registrations r
    JOIN Participating_Team pt ON r.PTeam_ID = pt.PTeam_ID
    WHERE pt.Event_ID = event_id_in;
    RETURN reg_count;
END$$
DELIMITER ;

-- F-2: Get Average Event Rating
DELIMITER $$
CREATE FUNCTION GetAvgEventRating(event_id_in INT)
RETURNS DECIMAL(3, 2)
READS SQL DATA
BEGIN
    DECLARE avg_rating DECIMAL(3, 2);
    SELECT AVG(Rating) INTO avg_rating
    FROM Feedback
    WHERE Event_ID = event_id_in;
    RETURN IFNULL(avg_rating, 0.00);
END$$
DELIMITER ;

-- F-3: Get Student Event Count (Participation)
DELIMITER $$
CREATE FUNCTION GetStudentEventCount(student_id_in INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE event_count INT;
    SELECT COUNT(DISTINCT pt.Event_ID) INTO event_count
    FROM PTeam_Members ptm
    JOIN Participating_Team pt ON ptm.PTeam_ID = pt.PTeam_ID
    WHERE ptm.Student_ID = student_id_in;
    RETURN event_count;
END$$
DELIMITER ;

-- F-4: Check Venue Availability
DELIMITER $$
CREATE FUNCTION CheckVenueAvailability(
    venue_id_in INT,
    date_in DATE,
    start_time_in TIME,
    end_time_in TIME
)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE conflict_count INT;
    SELECT COUNT(*) INTO conflict_count
    FROM Event
    WHERE Venue_ID = venue_id_in
      AND Date = date_in
      AND Start_Time < end_time_in
      AND End_Time > start_time_in;

    RETURN conflict_count = 0;
END$$
DELIMITER ;

-- F-5: Get Event Capacity Usage Percentage
DELIMITER $$
CREATE FUNCTION GetEventCapacityUsage(event_id_in INT)
RETURNS DECIMAL(5, 2)
READS SQL DATA
BEGIN
    DECLARE total_reg INT;
    DECLARE venue_capacity INT;

    SELECT GetTotalRegistrations(event_id_in) INTO total_reg;

    SELECT v.Capacity INTO venue_capacity
    FROM Event e
    JOIN Venue v ON e.Venue_ID = v.Venue_ID
    WHERE e.Event_ID = event_id_in;

    IF venue_capacity IS NULL OR venue_capacity = 0 THEN
        RETURN 0.00;
    ELSE
        RETURN (total_reg / venue_capacity) * 100;
    END IF;
END$$
DELIMITER ;

-- F-6: Get Event Name
DELIMITER $$
CREATE FUNCTION GetEventName(event_id_in INT)
RETURNS VARCHAR(100)
READS SQL DATA
BEGIN
    DECLARE event_name_out VARCHAR(100);
    SELECT Event_Name INTO event_name_out
    FROM Event
    WHERE Event_ID = event_id_in;
    RETURN event_name_out;
END$$
DELIMITER ;

-- F-7: Get Registration Count by Payment Status
DELIMITER $$
CREATE FUNCTION GetRegistrationCountByPaymentStatus(
    event_id_in INT,
    status_in VARCHAR(50)
)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE status_count INT;
    SELECT COUNT(r.Registration_ID) INTO status_count
    FROM Registrations r
    JOIN Participating_Team pt ON r.PTeam_ID = pt.PTeam_ID
    WHERE pt.Event_ID = event_id_in
      AND r.Payment_Status = status_in;
    RETURN status_count;
END$$
DELIMITER ;

-- F-8: Get Faculty Phone
DELIMITER $$
CREATE FUNCTION GetFacultyPhone(faculty_id_in INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE phone_no_out VARCHAR(20);
    SELECT Phone_No INTO phone_no_out
    FROM Faculty_Phone_No_Table
    WHERE Faculty_ID = faculty_id_in
    LIMIT 1;
    RETURN phone_no_out;
END$$
DELIMITER ;

-- F-9: Get Upcoming Event Count
DELIMITER $$
CREATE FUNCTION GetUpcomingEventCount()
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE upcoming_count INT;
    SELECT COUNT(*) INTO upcoming_count
    FROM Event
    WHERE Date >= CURDATE();
    RETURN upcoming_count;
END$$
DELIMITER ;

-- F-10: Get Event Duration in Hours
DELIMITER $$
CREATE FUNCTION GetEventDurationInHours(event_id_in INT)
RETURNS DECIMAL(5, 2)
READS SQL DATA
BEGIN
    DECLARE duration_seconds INT;
    SELECT TIME_TO_SEC(TIMEDIFF(End_Time, Start_Time)) INTO duration_seconds
    FROM Event
    WHERE Event_ID = event_id_in;
    RETURN duration_seconds / 3600;
END$$
DELIMITER ;

-- 
DELIMITER $$
CREATE FUNCTION GetStudentRegistrations(student_id_in INT) RETURNS JSON DETERMINISTIC
BEGIN
    DECLARE result JSON;
    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'Registration_ID', r.Registration_ID,
            'Event_Name', e.Event_Name,
            'Team_Name', COALESCE(pt.Team_Name, NULL),
            'Reg_Date', DATE_FORMAT(r.Reg_Date, '%Y-%m-%d'),
            'Payment_Status', r.Payment_Status
        )
    )
    INTO result
    FROM registrations r
    LEFT JOIN participating_team pt ON r.PTeam_ID = pt.PTeam_ID
    LEFT JOIN event e ON pt.Event_ID = e.Event_ID
    WHERE r.Student_ID = student_id_in;
    RETURN result;
END$$
DELIMITER ;

drop function GetStudentRegistrations;
SELECT ROUTINE_NAME AS Function_Name, ROUTINE_SCHEMA AS Database_Name, DATA_TYPE AS Return_Type, CREATED
FROM information_schema.ROUTINES
WHERE ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_SCHEMA = 'campus_event_management'
ORDER BY ROUTINE_NAME;