# Campus Event Management System
**DBMS Project - Team 17**

A robust, database-centric application for managing the entire lifecycle of events on a university campus, covering registration, resource allocation, and detailed administrative reporting.

## Tech Stack
- **Frontend:** Streamlit  
- **Backend:** Python  
- **Database:** MySQL

## Folder Structure
```text
Team_17_PES2UG23CS369_PES2UG23CS365 /
├── .gitignore
├── sql/
│   ├── .gitkeep
│   ├── DDL.sql             # Table and constraint definitions
│   ├── DML.sql             # Initial data population
│   ├── Procedures.sql      # All stored procedures 
│   ├── Functions.sql       # All scalar functions
│   └── Triggers.sql        # All triggers for integrity and audit logging
├── components/
│   ├── gitkeep
│   ├── admin.py            # Handles admin panel features and settings
│   ├── dashboard.py        # Provides main dashboard views and stats
│   ├── reg.py              # Manages event registration and cancellations
│   ├── reports.py          # Generates and displays performance reports
│   └── view_table.py       # Renders and manages table views in the UI
├── docs/
│   ├── .gitkeep
│   ├── Team_17_Review1.pdf # E-R Diagram and Relational Schema
│   └── report.pdf          # Final project report
├── UI.py                   # Main application entry point and Streamlit routing
├── requirements.txt        # Python dependencies
└── README.md
```

## Prerequisites

Before running the application, ensure you have the following installed and configured:
- Git installed locally in your system
- MySQL Server: Version 8.0 or later.
- Python: Version 3.8 or later.
- Required Libraries: Install the Python dependencies listed in `requirements.txt`

## Setup
1. **Clone the repository**
```
git clone https://github.com/nh-44/Team_17_PES2UG23CS369_PES2UG23CS365.git
cd Team_17_PES2UG23CS369_PES2UG23CS365
```

2. **Set up the database**<br>
Open MySQL Workbench or the MySQL command-line client, and execute all the SQL scripts located in the `sql/` folder to create the required database and tables.
Make sure to execute the files in the below order to ensure dependencies are created correctly.
```
SOURCE sql/DDL.sql;
SOURCE sql/Triggers.sql;
SOURCE sql/DML.sql;
SOURCE sql/Functions.sql;
SOURCE sql/Procedures.sql;
```

3. Create `.env` in the project root directory and add the following:
```
DB_HOST=localhost
DB_USER=<your-username>
DB_PASSWORD=<your-password>
DB_NAME=campus_event_management

ADMIN_EMAIL=<your-email-address>
ADMIN_PASSWORD=<your-email-password>
```

4. **Install dependencies.**<br>
```
pip install -r requirements.txt
```

5. **Run the application**<br>
```
streamlit run UI.py
```

## Team Members

- [Naveen S](https://github.com/nh-44) - PES2UG23CS369
- [Nandita R Nadig](https://github.com/NanditaRN06) - PES2UG23CS365

**Faculty Mentor:** Prof. Shilpa S
