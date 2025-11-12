import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv
import os
import pandas as pd
import streamlit as st

from components.dashboard import dashboard_page
from components.reg import registration_page
from components.admin import admin_page
from components.reports import reports_page
from components.view_table import table_viewer_page

st.set_page_config(page_title="Campus Event Management", layout="wide")
load_dotenv()

@st.cache_resource
def get_db_connection():
    try:
        return mysql.connector.connect(
            host=os.getenv("DB_HOST"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            database=os.getenv("DB_NAME"),
            # IMPORTANT: autocommit=False for explicit transaction control in execute_procedure
            autocommit=False 
        )
    except mysql.connector.Error as err:
        st.error(f"❌ DB Connection Error: {err}")
        return None

def db_conn():
    conn = get_db_connection()
    if not conn:
        st.stop()

    try:
        if not conn.is_connected():
            conn.reconnect(attempts=3, delay=2)
        return conn
    except mysql.connector.Error as err:
        st.error(f"❌ Database Error: {err}")
        st.stop()

# Helper: Execute Stored Procedure (Modified to return Status='Success' for DML)
def execute_procedure(conn, procedure_name, args=None):
    try:
        cursor = conn.cursor()
        if args:
            cursor.callproc(procedure_name, args)
        else:
            cursor.callproc(procedure_name)
        
        results = []
        columns = None
        for result in cursor.stored_results():
            if result.description:
                columns = [col[0] for col in result.description]
                results.extend(result.fetchall())

        conn.commit() # Explicitly commit after successful procedure execution

        cursor.close()

        if results:
            return pd.DataFrame(results, columns=columns), "Success"
        # For DML procedures that return no rows (like UPDATE), return dummy data
        return pd.DataFrame(columns=columns or ['Status']), "Success" 
    except Exception as e:
        conn.rollback() # Rollback on error
        return None, str(e)

# Helper: Execute Function
def execute_function(conn, func_call, params=None):
    try:
        cursor = conn.cursor()
        if params: 
            param_str = ', '.join(map(str, params))
            query = f"SELECT {func_call}({param_str}) AS result"
        else: query = f"SELECT {func_call} AS result"
        cursor.execute(query)
        result = cursor.fetchone()[0]
        cursor.close()
        return result
    except Exception as e:
        # st.error(f"❌ Function execution failed: {e}") # Suppress error for cleaner UI
        return None


# --- LOGIN LOGIC ---
if 'logged_in' not in st.session_state:
    st.session_state['logged_in'] = False
if 'user_role' not in st.session_state:
    st.session_state['user_role'] = 'Guest'

def login_form():
    st.sidebar.title("Admin Login")
    with st.sidebar.form("login_form"):
        email = st.text_input("Email")
        password = st.text_input("Password", type="password")
        submitted = st.form_submit_button("Login")

        if submitted:
            admin_email = os.getenv("ADMIN_EMAIL")
            admin_password = os.getenv("ADMIN_PASSWORD")
            
            if email == admin_email and password == admin_password:
                st.session_state['logged_in'] = True
                st.session_state['user_role'] = 'Admin'
                st.sidebar.success("Logged in as Admin!")
                st.rerun()
            else:
                st.sidebar.error("Invalid credentials.")
    
    if st.session_state['user_role'] == 'Admin' and st.sidebar.button("Logout"):
        st.session_state['logged_in'] = False
        st.session_state['user_role'] = 'Guest'
        st.rerun()

# Establish DB Connection and Helper Functions
connection = db_conn()
helper_funcs = {"execute_procedure": execute_procedure, "execute_function": execute_function}

# --- NAVIGATION ---
st.sidebar.title("Navigation")
menu_options = ["Dashboard", "Registration", "Reports", "Table Viewer"]

if st.session_state['user_role'] == 'Admin':
    menu_options.append("Admin")
    page = st.sidebar.radio("Go To", menu_options, index=0)
    
    # Render page based on selection
    if page == "Dashboard":
        dashboard_page(connection, **helper_funcs)
    elif page == "Registration":
        registration_page(connection, **helper_funcs)
    elif page == "Admin":
        admin_page(connection, **helper_funcs)
    elif page == "Reports":
        reports_page(connection, **helper_funcs)
    elif page == "Table Viewer":
        table_viewer_page(connection)
        
else: # Guest/Unauthenticated view
    login_form()
    
    # Guests can only access Dashboard, Registration, and Reports
    guest_options = ["Dashboard", "Registration", "Reports"]
    page = st.sidebar.radio("Go To", guest_options, index=0)

    if page == "Dashboard":
        dashboard_page(connection, **helper_funcs)
    elif page == "Registration":
        registration_page(connection, **helper_funcs)
    elif page == "Reports":
        reports_page(connection, **helper_funcs)