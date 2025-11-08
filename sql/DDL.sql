CREATE SCHEMA campus_event_management;
USE campus_event_management;

CREATE TABLE Venue (
    Venue_ID INT AUTO_INCREMENT PRIMARY KEY,
    Venue_Name VARCHAR(100),
    Capacity INT,
    Room_No VARCHAR(20),
    Building VARCHAR(50),
    Floor INT
);
desc Venue;

CREATE TABLE Faculty (
    Faculty_ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    Department VARCHAR(100)
);
desc Faculty;

CREATE TABLE Faculty_Phone_No_Table (
    Faculty_ID INT,
    Phone_No VARCHAR(20),
    PRIMARY KEY (Faculty_ID, Phone_No)
);
desc Faculty_Phone_No_Table;

CREATE TABLE Clubs (
    Club_ID INT AUTO_INCREMENT PRIMARY KEY,
    Club_Name VARCHAR(100),
    Description TEXT,
    Founded_Date DATE,
    Faculty_ID INT
);
desc Clubs;

CREATE TABLE Event (
    Event_ID INT AUTO_INCREMENT PRIMARY KEY,
    Event_Name VARCHAR(100),
    Event_Type VARCHAR(50),
    Date DATE,
    Start_Time TIME,
    End_Time TIME,
    Catering ENUM('Yes', 'No'),
    Budget DECIMAL(12,2),
    Club_ID INT,
    Venue_ID INT,
    Faculty_ID INT
);
desc Event;

CREATE TABLE Students (
    Student_ID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    Phone_No VARCHAR(20),
    Year_Of_Study INT,
    Department VARCHAR(100)
);
desc Students;

CREATE TABLE Grievances (
    Grievance_ID INT AUTO_INCREMENT PRIMARY KEY,
    Grievance_Text TEXT,
    Submitted_On DATE,
    Event_ID INT,
    Student_ID INT
);

CREATE TABLE Resources (
    Resource_ID INT AUTO_INCREMENT PRIMARY KEY,
    Resource_Name VARCHAR(100),
    Resource_Type VARCHAR(50),
    Quantity INT,
    Event_ID INT
);
desc Resources;

CREATE TABLE Feedback (
    Feedback_ID INT AUTO_INCREMENT PRIMARY KEY,
    Comments TEXT,
    Rating INT,
    Submitted_Date DATE,
    Student_ID INT,
    Event_ID INT
);
desc Feedback;

CREATE TABLE Participating_Team (
    PTeam_ID INT AUTO_INCREMENT PRIMARY KEY,
    Team_Name VARCHAR(100),
    No_of_Participants INT,
    Event_ID INT
);
desc Participating_Team;

CREATE TABLE PTeam_Members (
    PTeam_ID INT,
    Student_ID INT,
    PRIMARY KEY (PTeam_ID, Student_ID)
);
desc PTeam_Members;

CREATE TABLE Organising_Team (
    OTeam_ID INT AUTO_INCREMENT PRIMARY KEY,
    Formed_For VARCHAR(100),
    Event_ID INT
);
desc Organising_Team;

CREATE TABLE OTeam_Members (
    OTeam_ID INT,
    Student_ID INT,
    PRIMARY KEY (OTeam_ID, Student_ID)
);
desc OTeam_Members; 

CREATE TABLE Event_Admin (
    Admin_ID INT AUTO_INCREMENT PRIMARY KEY,
    Student_ID INT,
    OTeam_ID INT,
    Email VARCHAR(100)
);
desc Event_Admin;

CREATE TABLE Registrations (
    Registration_ID INT AUTO_INCREMENT PRIMARY KEY,
    Reg_For VARCHAR(100),
    Reg_Date DATE,
    Payment_Status VARCHAR(50),
    Student_ID INT,
    PTeam_ID INT
);  
desc Registrations;

CREATE TABLE Cancellations (
    Cancellation_ID INT AUTO_INCREMENT PRIMARY KEY,
    Cancelled_Date DATE,
    Reason TEXT,
    Reg_ID INT
);
desc Cancellations;

CREATE TABLE Audit_Logs (
    Log_ID INT AUTO_INCREMENT PRIMARY KEY,
    Action_Type VARCHAR(100),
    Performed_On TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Student_ID INT,
    Faculty_ID INT,
    Admin_ID INT,
    CHECK (
			(Student_ID IS NOT NULL AND Faculty_ID IS NULL AND Admin_ID IS NULL)
			OR (Student_ID IS NULL AND Faculty_ID IS NOT NULL AND Admin_ID IS NULL) 
			OR (Student_ID IS NULL AND Faculty_ID IS NULL AND Admin_ID IS NOT NULL)
    )
);
desc Audit_Logs;

ALTER TABLE Faculty_Phone_No_Table
ADD FOREIGN KEY (Faculty_ID) REFERENCES Faculty(Faculty_ID);

ALTER TABLE Clubs
ADD FOREIGN KEY (Faculty_ID) REFERENCES Faculty(Faculty_ID);

ALTER TABLE Event
ADD FOREIGN KEY (Club_ID) REFERENCES Clubs(Club_ID),
ADD FOREIGN KEY (Venue_ID) REFERENCES Venue(Venue_ID),
ADD FOREIGN KEY (Faculty_ID) REFERENCES Faculty(Faculty_ID);

ALTER TABLE Grievances
ADD FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID),
ADD FOREIGN KEY (Student_ID) REFERENCES Students(Student_ID);

ALTER TABLE Resources
ADD FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID);

ALTER TABLE Feedback
ADD FOREIGN KEY (Student_ID) REFERENCES Students(Student_ID),
ADD FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID);

ALTER TABLE Participating_Team
ADD FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID);

ALTER TABLE PTeam_Members
ADD FOREIGN KEY (Student_ID) REFERENCES Students(Student_ID),
ADD FOREIGN KEY (PTeam_ID) REFERENCES Participating_Team(PTeam_ID),
ADD CONSTRAINT fk_pteam FOREIGN KEY (PTeam_ID) REFERENCES Participating_Team(PTeam_ID) ON DELETE CASCADE;

ALTER TABLE Organising_Team
ADD FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID);

ALTER TABLE OTeam_Members
ADD FOREIGN KEY (Student_ID) REFERENCES Students(Student_ID),
ADD FOREIGN KEY (OTeam_ID) REFERENCES Organising_Team(OTeam_ID);

ALTER TABLE Event_Admin
ADD FOREIGN KEY (Student_ID) REFERENCES Students(Student_ID),
ADD FOREIGN KEY (OTeam_ID) REFERENCES Organising_Team(OTeam_ID);

ALTER TABLE Registrations
ADD FOREIGN KEY (Student_ID) REFERENCES Students(Student_ID),
ADD FOREIGN KEY (PTeam_ID) REFERENCES Participating_Team(PTeam_ID),
ADD CONSTRAINT fk_reg_pteam FOREIGN KEY (PTeam_ID) REFERENCES Participating_Team(PTeam_ID) ON DELETE SET NULL;

ALTER TABLE Cancellations
ADD FOREIGN KEY (Reg_ID) REFERENCES Registrations(Registration_ID);

ALTER TABLE Audit_Logs
ADD FOREIGN KEY (Student_ID) REFERENCES Students(Student_ID),
ADD FOREIGN KEY (Faculty_ID) REFERENCES Faculty(Faculty_ID),
ADD FOREIGN KEY (Admin_ID) REFERENCES Event_Admin(Admin_ID);