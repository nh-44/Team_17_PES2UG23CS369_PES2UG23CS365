import streamlit as st
import pandas as pd
import mysql.connector

def admin_page(conn, execute_procedure, execute_function):
    st.title("⚙️ Admin & Setup Operations")

    # ====================================================================
    st.subheader("1. New Event Creation")
    with st.expander("➕ Create a New Event"):
        with st.form("Add New Event Form"):
            # Fetch FK references for selection boxes
            try:
                clubs_df = pd.read_sql_query("SELECT Club_ID, Club_Name FROM Clubs", conn)
                venue_df = pd.read_sql_query("SELECT Venue_ID, Venue_Name FROM Venue", conn)
                faculty_df = pd.read_sql_query("SELECT Faculty_ID, Name FROM Faculty", conn)
                
                club_map = clubs_df.set_index('Club_Name')['Club_ID'].to_dict()
                venue_map = venue_df.set_index('Venue_Name')['Venue_ID'].to_dict()
                faculty_map = faculty_df.set_index('Name')['Faculty_ID'].to_dict()
                
            except Exception as e:
                st.error(f"Error fetching lookup data: {e}")
                # Use return instead of st.stop() since st.stop() may be restricted
                # return

            event_name = st.text_input("Event Name")
            event_type = st.text_input("Event Type (e.g., Workshop, Competition, Seminar)")
            date = st.date_input("Date")
            col_t1, col_t2 = st.columns(2)
            start_time = col_t1.time_input("Start Time", value=pd.to_datetime('09:00:00').time())
            end_time = col_t2.time_input("End Time", value=pd.to_datetime('17:00:00').time())
            catering = st.radio("Catering Required", ['Yes', 'No'])
            budget = st.number_input("Budget (e.g., 50000.00)", min_value=0.00, value=10000.00)
            
            # Select boxes using display name but storing ID
            club_name = st.selectbox("Organizing Club", clubs_df['Club_Name'].tolist())
            venue_name = st.selectbox("Venue", venue_df['Venue_Name'].tolist())
            faculty_name = st.selectbox("Faculty Incharge", faculty_df['Name'].tolist())

            submitted = st.form_submit_button("Create Event")

            if submitted:
                try:
                    club_id = club_map[club_name]
                    venue_id = venue_map[venue_name]
                    faculty_id = faculty_map[faculty_name]
                    
                    cursor = conn.cursor()
                    cursor.execute(
                        """
                        INSERT INTO Event (Event_Name, Event_Type, Date, Start_Time, End_Time, Catering, Budget, Club_ID, Venue_ID, Faculty_ID)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """,
                        (event_name, event_type, date, start_time.strftime("%H:%M:%S"), end_time.strftime("%H:%M:%S"), catering, budget, club_id, venue_id, faculty_id)
                    )
                    conn.commit()
                    st.success(f"✅ Event '{event_name}' created successfully with ID {cursor.lastrowid}.")
                except Exception as e:
                    st.error(f"❌ Failed to create event: {e}")
                    conn.rollback()
                finally:
                    cursor.close()

    # ====================================================================
    st.subheader("2. Event Configuration & Staffing")
    
    # P-9: Assign Organising Team Member
    col_a, col_b = st.columns(2)
    with col_a.form("Assign Organising Team Member"):
        st.caption("P-9: Assign Organising Team Member")
        oteam_id = st.number_input("Organising Team ID", min_value=1, value=1, key="p9_oteam")
        student_id_p9 = st.number_input("Student ID to Assign", min_value=1, value=4009, key="p9_student")
        
        submitted = st.form_submit_button("Assign Member (P-9)")

        if submitted:
            df_result, error = execute_procedure(conn, "AssignOrganisingTeamMember", args=(oteam_id, student_id_p9))
            if error == "Success":
                if df_result is not None and not df_result.empty:
                    st.success(df_result.iloc[0, 0])
                else:
                    st.success(f"Student {student_id_p9} assigned to OTeam {oteam_id}.")
            else:
                st.error(error)

    # P-6: Update Team Budget
    with col_b.form("Update Team Budget"):
        st.caption("P-6: Update Event Budget")
        event_id_p6 = st.number_input("Event ID", min_value=1, value=3004, key="p6_event")
        new_budget = st.number_input("New Budget", min_value=0.00, value=50000.00, key="p6_budget")
        submitted = st.form_submit_button("Update Budget (P-6)")

        if submitted:
            df_result, error = execute_procedure(conn, "UpdateTeamBudget", args=(event_id_p6, new_budget))
            if error == "Success":
                if df_result is not None and not df_result.empty:
                    st.success(df_result.iloc[0, 0])
                else:
                    st.success(f"Budget updated to {new_budget} for Event ID {event_id_p6}.")
            else:
                st.error(error)
                
    # ====================================================================
    st.subheader("3. Core Event Updates")
    col1, col2 = st.columns(2)

    with col1.form("Update Faculty Incharge"):
        st.caption("P-4: Update Faculty Incharge")
        event_id = st.number_input("Event ID", min_value=1, value=3004, key="p4_event")
        new_faculty_id = st.number_input("New Faculty ID", min_value=1, value=1006, key="p4_faculty")
        submitted = st.form_submit_button("Update Faculty (P-4)")

        if submitted:
            df_result, error = execute_procedure(conn, "UpdateFacultyIncharge", args=(event_id, new_faculty_id))
            if error == "Success":
                if df_result is not None and not df_result.empty:
                    st.success(df_result.iloc[0, 0])
                else:
                    st.success(f"Faculty updated for Event ID {event_id}.")
            else:
                st.error(error)
    
    # New Form: Update Event Date and Time
    with col2.form("Update Event Date and Time"):
        st.caption("Raw SQL: Update Event Date/Time")
        event_id_dt = st.number_input("Event ID to Update", min_value=1, value=3004, key="dt_event")
        
        # New date/time inputs for the update
        new_date = st.date_input("New Date", key="dt_new_date")
        col_dt1, col_dt2 = st.columns(2)
        new_start_time = col_dt1.time_input("New Start Time", key="dt_new_start", value=pd.to_datetime('10:00:00').time())
        new_end_time = col_dt2.time_input("New End Time", key="dt_new_end", value=pd.to_datetime('16:00:00').time())
        
        dt_submit = st.form_submit_button("Update Date/Time (Raw SQL)")
        
        if dt_submit:
            try:
                # F-4 check before update (using raw SQL is risky, so we double check)
                start_str = new_start_time.strftime("%H:%M:%S")
                end_str = new_end_time.strftime("%H:%M:%S")
                
                # Fetch current venue_id to check availability
                cursor = conn.cursor()
                cursor.execute("SELECT Venue_ID FROM Event WHERE Event_ID = %s", (event_id_dt,))
                venue_id_check = cursor.fetchone()[0]
                
                venue_ok = execute_function(conn, f"CheckVenueAvailability({venue_id_check}, '{new_date}', '{start_str}', '{end_str}')")
                
                if venue_ok == 0:
                    st.error("❌ Cannot update date/time: New schedule conflicts with another event at the same venue.")
                else:
                    # Perform the Raw SQL Update
                    cursor.execute(
                        """
                        UPDATE Event 
                        SET Date = %s, Start_Time = %s, End_Time = %s
                        WHERE Event_ID = %s
                        """,
                        (new_date, start_str, end_str, event_id_dt)
                    )
                    conn.commit()
                    st.success(f"✅ Date/Time updated for Event ID {event_id_dt}. (New Date: {new_date}, {start_str}-{end_str})")
            except Exception as e:
                conn.rollback()
                st.error(f"❌ Failed to update Date/Time: {e}")
            finally:
                cursor.close()


    # Form for P-8: Update Event Venue
    with col1.form("Update Event Venue"):
        st.caption("P-8: Update Event Venue (Venue ID only)")
        event_id_v = st.number_input("Event ID", min_value=1, value=3004, key="p8_event")
        new_venue_id = st.number_input("New Venue ID", min_value=1, value=11005, key="p8_venue_id")

        st.caption("--- Availability Check (F-4) ---")
        # For the check, we need the event's current date/time
        # Fetch current event details for F-4 check consistency
        try:
            current_details = pd.read_sql_query("SELECT Date, Start_Time, End_Time FROM Event WHERE Event_ID = %s", conn, params=(event_id_v,)).iloc[0]
            check_date = st.date_input("Check Date (current event date)", value=current_details['Date'], key="p8_venue_date")
            start_time = st.time_input("Start Time (current event start)", value=current_details['Start_Time'], key="p8_venue_start")
            end_time = st.time_input("End Time (current event end)", value=current_details['End_Time'], key="p8_venue_end")
            
            start_str = start_time.strftime("%H:%M:%S")
            end_str = end_time.strftime("%H:%M:%S")
            venue_ok = execute_function(conn, f"CheckVenueAvailability({new_venue_id}, '{check_date}', '{start_str}', '{end_str}')") # F-4
        except Exception:
            venue_ok = None
            st.warning("Could not fetch current event details for F-4 check.")

        if venue_ok is not None:
            if venue_ok == 0:
                st.warning("⚠️ Venue looks booked at this time.")
            else:
                st.info("✅ Venue is available for this time window.")
        
        st_submit = st.form_submit_button("Update Venue (P-8)")

        if st_submit:
            df_result, error = execute_procedure(conn, "UpdateEventVenue", args=(event_id_v, new_venue_id)) # P-8
            if error == "Success":
                st.success(f"Venue updated for Event ID {event_id_v}.")
            else:
                st.error(error)

    # ====================================================================
    st.subheader("4. Resource Allocation")
    # P-3: Allocate Resource to Event
    with st.form("Allocate Resources"):
        st.caption("P-3: Allocate Resource to Event (Adds quantity if resource exists)")
        event_id_r = st.number_input("Event ID", min_value=1, value=3004, key="p3_event")
        resource_name = st.text_input("Resource Name (e.g., Projector, Laptop)", key="p3_name")
        resource_type = st.text_input("Resource Type (e.g., Equipment, Manpower, Material)", key="p3_type")
        quantity = st.number_input("Quantity", min_value=1, value=1, key="p3_qty")
        
        submitted = st.form_submit_button("Allocate Resource (P-3)")
        
        if submitted:
            df_result, error = execute_procedure(conn, "AllocateResourceToEvent", args=(event_id_r, resource_name, resource_type, quantity)) # P-3
            if error == "Success":
                if df_result is not None and not df_result.empty:
                    st.success(df_result.iloc[0, 0])
                else:
                    st.success(f"Resource '{resource_name}' allocated/updated for Event ID {event_id_r}.")
            else:
                st.error(error)