USE campus_event_management;

-- Trigger 1: Feedback — ensure student is registered for that event
DELIMITER $$

CREATE TRIGGER before_feedback_insert
BEFORE INSERT ON feedback
FOR EACH ROW
BEGIN
    DECLARE reg_count INT;
    SELECT COUNT(*) INTO reg_count
    FROM registrations r
    WHERE r.Student_ID = NEW.Student_ID
      AND r.PTeam_ID IN (
          SELECT PTeam_ID FROM participating_team WHERE Event_ID = NEW.Event_ID
      );
      
    IF reg_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student cannot submit feedback without registration for this event.';
    END IF;
END$$

DELIMITER ;

-- Trigger 2: Grievances — ensure student participated before grievance
DELIMITER $$

CREATE TRIGGER before_grievance_insert
BEFORE INSERT ON grievances
FOR EACH ROW
BEGIN
    DECLARE part_count INT;
    SELECT COUNT(*) INTO part_count
    FROM pteam_members pm
    JOIN participating_team pt ON pm.PTeam_ID = pt.PTeam_ID
    WHERE pm.Student_ID = NEW.Student_ID
      AND pt.Event_ID = NEW.Event_ID;

    IF part_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student must have participated before submitting a grievance.';
    END IF;
END$$

DELIMITER ;

-- Trigger 3: Faculty — prevent deleting guiding faculty
DELIMITER $$

CREATE TRIGGER before_faculty_delete
BEFORE DELETE ON faculty
FOR EACH ROW
BEGIN
    DECLARE ref_count INT;
    SELECT COUNT(*) INTO ref_count
    FROM clubs WHERE Faculty_ID = OLD.Faculty_ID;
    IF ref_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete faculty guiding a club.';
    END IF;

    SELECT COUNT(*) INTO ref_count
    FROM event WHERE Faculty_ID = OLD.Faculty_ID;
    IF ref_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete faculty assigned to an event.';
    END IF;
END$$

DELIMITER ;

-- Trigger 4: Registrations — prevent registration for invalid or past event
DELIMITER $$

CREATE TRIGGER before_registration_insert
BEFORE INSERT ON registrations
FOR EACH ROW
BEGIN
    DECLARE ev_date DATE;
    SELECT Date INTO ev_date FROM event e
    JOIN participating_team p ON e.Event_ID = p.Event_ID
    WHERE p.PTeam_ID = NEW.PTeam_ID;

    IF ev_date IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot register: Event does not exist.';
    ELSEIF ev_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot register: Event date is in the past.';
    END IF;
END$$

DELIMITER ;

-- Trigger 5: Audit Logs — prevent deletion
DELIMITER $$

CREATE TRIGGER before_audit_delete
BEFORE DELETE ON audit_logs
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Audit logs cannot be deleted.';
END$$

DELIMITER ;

-- Trigger 6: Feedback — ensure rating between 1 and 5
DELIMITER $$

CREATE TRIGGER before_feedback_rating
BEFORE INSERT ON feedback
FOR EACH ROW
BEGIN
    IF NEW.Rating < 1 OR NEW.Rating > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Feedback rating must be between 1 and 5.';
    END IF;
END$$

DELIMITER ;

-- Trigger 7: PTeam Members — prevent duplicate participation in same event
DELIMITER $$

CREATE TRIGGER before_pteam_member_insert
BEFORE INSERT ON pteam_members
FOR EACH ROW
BEGIN
    DECLARE evt_id INT;
    DECLARE exists_count INT;

    SELECT Event_ID INTO evt_id FROM participating_team WHERE PTeam_ID = NEW.PTeam_ID;

    SELECT COUNT(*) INTO exists_count
    FROM pteam_members pm
    JOIN participating_team pt ON pm.PTeam_ID = pt.PTeam_ID
    WHERE pm.Student_ID = NEW.Student_ID AND pt.Event_ID = evt_id;

    IF exists_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student already participates in another team for this event.';
    END IF;
END$$

DELIMITER ;

-- Trigger 8: Feedback — after insert, add entry to audit log
DELIMITER $$

CREATE TRIGGER after_feedback_insert
AFTER INSERT ON feedback
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (Action_Type, Student_ID)
    VALUES (CONCAT('Feedback submitted for Event ID ', NEW.Event_ID), NEW.Student_ID);
END$$

DELIMITER ;

-- Trigger 9: Registrations — after insert, add entry to audit log
DELIMITER $$

CREATE TRIGGER after_registration_insert
AFTER INSERT ON registrations
FOR EACH ROW
BEGIN
    DECLARE evt_id INT;
    SELECT Event_ID INTO evt_id FROM participating_team WHERE PTeam_ID = NEW.PTeam_ID;

    INSERT INTO audit_logs (Action_Type, Student_ID)
    VALUES (CONCAT('Registration done for Event ID ', evt_id), NEW.Student_ID);
END$$

DELIMITER ;

-- Trigger 10: Cancellations — after insert, log cancellation
DELIMITER $$

CREATE TRIGGER after_cancellation_insert
AFTER INSERT ON cancellations
FOR EACH ROW
BEGIN
    DECLARE stud_id INT;
    DECLARE evt_id INT;

    SELECT Student_ID, pt.Event_ID
    INTO stud_id, evt_id
    FROM registrations r
    JOIN participating_team pt ON r.PTeam_ID = pt.PTeam_ID
    WHERE r.Registration_ID = NEW.Reg_ID;

    INSERT INTO audit_logs (Action_Type, Student_ID)
    VALUES (CONCAT('Registration cancelled for Event ID ', evt_id), stud_id);
END$$

DELIMITER ;

-- Trigger 11: Grievances — after insert, log grievance
DELIMITER $$

CREATE TRIGGER after_grievance_insert
AFTER INSERT ON grievances
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (Action_Type, Student_ID)
    VALUES (CONCAT('Grievance submitted for Event ID ', NEW.Event_ID), NEW.Student_ID);
END$$

DELIMITER ;

SHOW TRIGGERS;