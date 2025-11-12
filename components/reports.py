import streamlit as st
import pandas as pd
import mysql.connector

def reports_page(conn, execute_procedure, execute_function):
    st.title("📈 Reports and Detailed Analytics")

    # ====================================================================
    st.subheader("1. Detailed Event Report & Metrics")
    report_event_id = st.number_input("Event ID for Report", min_value=1, value=3001)
    
    col_rep, col_met = st.columns([2, 1])

    with col_rep:
        if st.button("Generate Detailed Report (P-5)"):
            # P-5: GenerateEventReport
            df_report, error = execute_procedure(conn, "GenerateEventReport", args=(int(report_event_id),))
            if error == "Success":
                if df_report is not None and not df_report.empty:
                    st.markdown("##### Event Summary Report")
                    # Transpose for easier reading in Streamlit
                    df_report_display = df_report.transpose().reset_index()
                    df_report_display.columns = ["Metric", "Value"]
                    st.dataframe(df_report_display, hide_index=True, use_container_width=True)
                else:
                    st.warning(f"No data found for Event ID {report_event_id}.")
            else:
                st.error(error)

    with col_met:
        st.markdown("##### Event Metrics (Functions)")
        # F-7: GetRegistrationCountByPaymentStatus
        status = st.selectbox("Registration Status", ["Paid", "Pending", "Cancelled"], key="reg_status")
        reg_count = execute_function(conn, f"GetRegistrationCountByPaymentStatus({report_event_id}, '{status}')")
        st.metric(f"Registrations ({status})", reg_count if reg_count is not None else 0)

        # F-5: GetEventCapacityUsage
        usage = execute_function(conn, f"GetEventCapacityUsage({report_event_id})")
        try:
            st.metric("Venue Usage", f"{float(usage):.2f}%" if usage is not None else "N/A")
        except Exception:
            st.metric("Venue Usage", "N/A")
            
        # F-10: Get Event Duration in Hours
        duration = execute_function(conn, f"GetEventDurationInHours({report_event_id})")
        try:
            st.metric("Duration", f"{float(duration):.2f} hrs" if duration is not None else "N/A")
        except Exception:
            st.metric("Duration", "N/A")
            
    st.markdown("---")
    # ====================================================================
    st.subheader("2. Event Filtering and Listings")
    
    # P-7: Get Events by Club and Type
    with st.expander("Filter Events by Club and Type (P-7)"):
        # Fetch Club and Event Types for selection boxes
        try:
            clubs_df = pd.read_sql_query("SELECT Club_ID, Club_Name FROM Clubs", conn)
            types_df = pd.read_sql_query("SELECT DISTINCT Event_Type FROM Event", conn)
            
            club_list = clubs_df['Club_Name'].tolist()
            type_list = types_df['Event_Type'].tolist()
            club_map = clubs_df.set_index('Club_Name')['Club_ID'].to_dict()
            
        except Exception as e:
            st.error(f"Error fetching lookup data: {e}")
            # return

        col_c, col_t = st.columns(2)
        selected_club_name = col_c.selectbox("Select Club", club_list, key="filter_club")
        selected_event_type = col_t.selectbox("Select Event Type", type_list, key="filter_type")
        
        if st.button("Get Events (P-7)"):
            club_id = club_map.get(selected_club_name)
            if club_id:
                df_events, error = execute_procedure(conn, "GetEventsByClubAndType", args=(club_id, selected_event_type)) # P-7
                if error == "Success" and df_events is not None and not df_events.empty:
                    st.dataframe(df_events, hide_index=True, use_container_width=True)
                else:
                    st.info(f"No events found for {selected_club_name} of type {selected_event_type}. Error: {error}")
            else:
                st.warning("Please select a valid club.")
                
    st.markdown("---")
    # ====================================================================
    st.subheader("3. Resource and Staffing Details")
    
    # Resources Used
    with st.expander("Resources Used for an Event"):
        event_id_res = st.number_input("Event ID", min_value=1, value=3001, key="res_event")
        if st.button("Show Resources", key="show_res_btn"):
            try:
                # Direct SQL query to fetch resources
                query = "SELECT Resource_Name, Resource_Type, Quantity FROM Resources WHERE Event_ID = %s"
                df_resources = pd.read_sql_query(query, conn, params=(event_id_res,))
                if not df_resources.empty:
                    st.dataframe(df_resources, hide_index=True, use_container_width=True)
                else:
                    st.info(f"No resources allocated for Event ID {event_id_res}.")
            except Exception as e:
                st.error(f"Error fetching resources: {e}")
                
    # Organizing Team Members
    with st.expander("Organising Team Members for an Event"):
        event_id_ot = st.number_input("Event ID", min_value=1, value=3001, key="ot_event")
        if st.button("Show Organising Team", key="show_ot_btn"):
            try:
                # Direct SQL query to join OTeam_Members and Students
                query = """
                    SELECT s.Student_ID, s.Name, o.Formed_For
                    FROM OTeam_Members otm
                    JOIN Students s ON otm.Student_ID = s.Student_ID
                    JOIN Organising_Team o ON otm.OTeam_ID = o.OTeam_ID
                    WHERE o.Event_ID = %s
                """
                df_ot = pd.read_sql_query(query, conn, params=(event_id_ot,))
                if not df_ot.empty:
                    st.dataframe(df_ot, hide_index=True, use_container_width=True)
                else:
                    st.info(f"No organising team members found for Event ID {event_id_ot}.")
            except Exception as e:
                st.error(f"Error fetching organising team: {e}")
                
    st.markdown("---")
    # ====================================================================
    st.subheader("4. Grievance Review")
    
    # Latest Grievance(s)
    num_grievances = st.slider("Number of Latest Grievances to Show", 1, 10, 3)
    if st.button("Show Latest Grievances"):
        try:
            # Direct SQL query for latest grievances
            query = """
                SELECT g.Grievance_ID, e.Event_Name, s.Name AS Student_Name, g.Submitted_On, g.Grievance_Text
                FROM Grievances g
                JOIN Event e ON g.Event_ID = e.Event_ID
                JOIN Students s ON g.Student_ID = s.Student_ID
                ORDER BY g.Submitted_On DESC, g.Grievance_ID DESC
                LIMIT %s
            """
            df_grievances = pd.read_sql_query(query, conn, params=(num_grievances,))
            if not df_grievances.empty:
                st.markdown(f"##### Top {len(df_grievances)} Latest Grievances")
                st.dataframe(df_grievances, hide_index=True, use_container_width=True)
            else:
                st.info("No grievances found.")
        except Exception as e:
            st.error(f"Error fetching grievances: {e}")