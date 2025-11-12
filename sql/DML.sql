USE campus_event_management;

INSERT INTO faculty (Faculty_ID, Name, Email, Department) VALUES
(1001, 'Dr. Meera Krishnan', 'meera.k@campus.edu', 'Computer Science'),
(1002, 'Dr. Rajesh Nair', 'rajesh.n@campus.edu', 'Electronics'),
(1003, 'Dr. Asha Patel', 'asha.p@campus.edu', 'Mechanical'),
(1004, 'Dr. Varun Menon', 'varun.m@campus.edu', 'Civil'),
(1005, 'Dr. Neha Shenoy', 'neha.s@campus.edu', 'Computer Science'),
(1006, 'Dr. Ravi Kumar', 'ravi.k@campus.edu', 'Electronics');
select * from faculty;

INSERT INTO faculty_phone_no_table (Faculty_ID, Phone_No) VALUES
(1001, '9876543210'), (1001, '9855602345'), 
(1002, '9867321456'),
(1003, '9823456712'), (1003, '9882291092'), 
(1004, '9845123987'),
(1005, '9876549876'), 
(1006, '9832109876'), (1006, '9856451234');
select * from faculty_phone_no_table;

INSERT INTO clubs (Club_ID, Club_Name, Description, Founded_Date, Faculty_ID) VALUES
(2001, 'Tech Innovators', 'A club for tech enthusiasts and coding competitions.', '2019-07-12', 1005),
(2002, 'Circuit Breakers', 'Focus on electronics and embedded systems.', '2018-03-09', 1002),
(2003, 'AutoMech Society', 'Dedicated to mechanical innovations.', '2020-11-25', 1003),
(2004, 'EcoBuilders', 'Civil students promoting sustainable infrastructure.', '2017-06-30', 1004);
select * from clubs;

INSERT INTO venue (Venue_ID, Venue_Name, Capacity, Room_No, Building, Floor) VALUES
(11001, 'Auditorium', 300, 'Main', 'Block A', 1),
(11002, 'Lab', 80, 'Innovation Lab', 'Tech Building', 2),
(11003, 'Seminar Hall - 1', 140, 'Hall 1', 'Block D', 1),
(11004, 'Seminar Hall - 2', 140, 'Hall 2', 'Block D', 1),
(11005, 'Seminar Hall - 3', 120, 'Hall 3', 'Block E', 1),
(11006, 'Classroom', 80, '100A', 'Tech Building', 1);
select * from venue;

INSERT INTO event (Event_ID, Event_Name, Event_Type, Date, Start_Time, End_Time, Catering, Budget, Club_ID, Venue_ID, Faculty_ID) VALUES
(3001, 'Hackathon 2025', 'Competition', '2025-12-10', '09:00:00', '18:00:00', 'Yes', 50000, 2001, 11001, 1001), 
(3002, 'ElectroQuest', 'Workshop', '2025-11-20', '10:00:00', '16:00:00', 'No', 20000, 2002, 11002, 1002),
(3003, 'AutoCAD Challenge', 'Competition', '2025-12-02', '10:00:00', '17:00:00', 'Yes', 30000, 2003, 11003, 1003),
(3004, 'Green Campus Design', 'Seminar', '2025-11-25', '11:00:00', '14:00:00', 'No', 15000, 2004, 11004, 1004),
(3005, 'Electronics Expo', 'Exhibition', '2025-12-15', '12:00:00', '17:00:00', 'Yes', 25000, 2002, 11001, 1005),
(3006, 'AI & Robotics Expo', 'Exhibition', '2025-12-05', '09:00:00', '15:00:00', 'Yes', 40000, 2002, 11001, 1001),
(3007, 'Data Science Bootcamp', 'Workshop', '2025-12-12', '09:30:00', '16:30:00', 'Yes', 35000, 2003, 11002, 1006),
(3008, 'Sustainable Engineering Fair', 'Exhibition', '2025-12-18', '10:00:00', '18:00:00', 'No', 45000, 2004, 11003, 1006); 
select * from event;

INSERT INTO students (Student_ID, Name, Email, Phone_No, Year_Of_Study, Department) VALUES
(4001, 'Ananya Rao', 'ananya.r@campus.edu', '9876501234', 3, 'Computer Science'),
(4002, 'Rohit Menon', 'rohit.m@campus.edu', '9847034567', 2, 'Electronics'),
(4003, 'Sneha Iyer', 'sneha.i@campus.edu', '9867012345', 3, 'Mechanical'),
(4004, 'Karthik Nair', 'karthik.n@campus.edu', '9895016789', 4, 'Civil'),
(4005, 'Diya Thomas', 'diya.t@campus.edu', '9812345670', 2, 'Computer Science'),
(4006, 'Manoj Pillai', 'manoj.p@campus.edu', '9823012345', 3, 'Electronics'),
(4007, 'Isha Kapoor', 'isha.k@campus.edu', '9801234567', 1, 'Mechanical'),
(4008, 'Vikram Singh', 'vikram.s@campus.edu', '9834123456', 4, 'Civil'),
(4009, 'Priya Desai', 'priya.d@campus.edu', '9856234789', 2, 'Computer Science');
select * from students;

INSERT INTO participating_team (PTeam_ID, Team_Name, Event_ID) VALUES
(5001, 'Code Masters', 3001),
(5002, 'Circuit Ninjas', 3002),
(5003, 'AutoMech Champs', 3003),
(5004, 'Eco Designers', 3004),
(5005, 'Electro Warriors', 3005);
select * from participating_team;

INSERT INTO pteam_members (PTeam_ID, Student_ID) VALUES
(5001, 4001),
(5001, 4005),
(5002, 4002),
(5003, 4003),
(5004, 4004),
(5005, 4006);
select * from pteam_members;

INSERT INTO registrations (Registration_ID, Reg_For, Reg_Date, Payment_Status, Student_ID, PTeam_ID) VALUES
(6001, 'Hackathon 2025', '2025-10-08', 'Paid', 4001, 5001),
(6002, 'Hackathon 2025', '2025-10-08', 'Paid', 4005, 5001),
(6003, 'ElectroQuest', '2025-10-09', 'Paid', 4002, 5002),
(6004, 'AutoCAD Challenge', '2025-10-10', 'Paid', 4003, 5003),
(6005, 'Green Campus Design', '2025-10-11', 'Paid', 4004, 5004),
(6006, 'Electronics Expo', '2025-10-11', 'Paid', 4006, 5005);
select * from registrations;

INSERT INTO feedback (Feedback_ID, Student_ID, Event_ID, Rating, Comments, Submitted_Date) VALUES
(8001, 4001, 3001, 5, 'Amazing event! Great mentors.', '2025-12-11'),
(8002, 4005, 3001, 4, 'Loved the hackathon challenges.', '2025-12-11'),
(8003, 4002, 3002, 5, 'Very informative and interactive.', '2025-11-21'),
(8004, 4004, 3004, 3, 'Interesting but could be longer.', '2025-11-26');
select * from feedback;

INSERT INTO grievances (Grievance_ID, Student_ID, Event_ID, Grievance_Text, Submitted_On) VALUES
(9001, 4001, 3001, 'Team conflict regarding submission timing.', '2025-12-12'),
(9002, 4002, 3002, 'Technical issue during session.', '2025-11-22');
select * from grievances;

INSERT INTO cancellations (Cancellation_ID, Reg_ID, Cancelled_Date, Reason) VALUES
(7001, 6003, '2025-11-15', 'Schedule conflict'),
(7002, 6005, '2025-11-20', 'Health reasons');
select * from cancellations;

INSERT INTO Organising_Team (OTeam_ID, Formed_For, Event_ID) VALUES
(7001, 'Hackathon Logistics', 3001), 
(7002, 'ElectroQuest Setup', 3002),
(7003, 'AutoCAD Logistics', 3003), 
(7004, 'Green Campus Admin', 3004); 
select * from Organising_Team;

INSERT INTO OTeam_Members (OTeam_ID, Student_ID) VALUES
(7001, 4001),
(7001, 4005),
(7002, 4002),
(7003, 4003),
(7004, 4004),
(7004, 4008);
select * from OTeam_Members;

INSERT INTO Event_Admin (Admin_ID, Student_ID, OTeam_ID, Email) VALUES
(1, 4001, 7001, 'admin_ananya@campus.edu'), 
(2, 4002, 7002, 'admin_rohit@campus.edu'), 
(3, 4004, 7004, 'admin_karthik@campus.edu'); 
select * from Event_Admin;

INSERT INTO Resources (Resource_ID, Resource_Name, Resource_Type, Quantity, Event_ID) VALUES
(10001, 'Projector', 'Equipment', 5, 3001), 
(10002, 'Laptops (Gaming)', 'Equipment', 20, 3001), 
(10003, 'Solder Stations', 'Equipment', 10, 3002), 
(10004, 'A3 Plotter', 'Equipment', 2, 3003), 
(10005, 'Coffee & Snacks', 'Catering', 1, 3005),
(10006, 'Security Personnel', 'Manpower', 4, 3008); 
select * from Resources;

INSERT INTO Audit_Logs (Log_ID, Action_Type, Student_ID, Faculty_ID, Admin_ID) VALUES
(1, 'System Setup Complete by Student Lead', 4001, NULL, NULL),
(2, 'Event Budget Approved', NULL, 1001, NULL),
(3, 'Event Admin Initial Login', NULL, NULL, 1);
select * from Audit_Logs;

--  Trigger test 
INSERT INTO pteam_members (PTeam_ID, Student_ID) VALUES (5001, 4001);
INSERT INTO registrations (Registration_ID, Student_ID, PTeam_ID, Reg_Date) VALUES (6007, 4002, 99999, '2025-10-12');
INSERT INTO feedback (Feedback_ID, Student_ID, Event_ID, Rating, Comments, Submitted_Date) VALUES (8005, 4006, 3003, 4, 'Cool event', '2025-12-03');
INSERT INTO feedback (Feedback_ID, Student_ID, Event_ID, Rating, Comments, Submitted_Date) VALUES (8006, 4001, 3001, 6, 'Invalid rating test', '2025-12-12');
INSERT INTO grievances (Grievance_ID, Student_ID, Event_ID, Grievance_Text, Submitted_On) VALUES (9003, 4006, 3003, 'Unfair judging process.', '2025-12-03');
INSERT INTO cancellations (Cancellation_ID, Reg_ID, Cancelled_Date, Reason) VALUES (7003, 99999, '2025-11-25', 'Invalid registration test');

