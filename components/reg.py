import streamlit as st
import pandas as pd
import mysql.connector

def registration_page(conn, execute_procedure, execute_function):
    st.title("🎟️ Event Registration & Cancellation")

    tabs = st.tabs(["📝 Register", "❌ Cancel Registration"])

    # ======================= REGISTER TAB =======================
    with tabs[0]:
        st.subheader("Register for an Event")
        st.caption("P-1: Register for Event (Solo/Team)")

        student_id = st.number_input("Enter Student ID", min_value=1, step=1)
        
        # Fetch available events (future events)
        events_df, status = execute_procedure(conn, "GetFutureEvents") # P-11

        if events_df is None or events_df.empty:
            st.warning("⚠️ No upcoming events found.")
            return

        # Event selection
        event_name = st.selectbox("Select Event", events_df["Event_Name"].tolist())
        event_id = int(events_df.loc[events_df["Event_Name"] == event_name, "Event_ID"].values[0])

        reg_for = st.selectbox("Participation Type", ["Solo", "Team"])

        member_ids = []
        team_name = None

        if reg_for == "Team":
            team_name = st.text_input("Enter Team Name", f"Team_{student_id}", key="team_name_input")
            num_members = st.selectbox("Number of Team Members (including you)", [2, 3, 4], index=0)

            for i in range(2, num_members + 1):
                member_id = st.number_input(f"Enter Member-{i} Student ID", min_value=1, step=1, key=f"mem_{i}_reg")
                if member_id > 0:
                    member_ids.append(member_id)
            
            # Validate input
            if team_name is None or team_name.strip() == "":
                st.error("Team registration requires a Team Name.")
                return

        payment_status = st.selectbox("Payment Status", ["Paid", "Pending", "Cancelled"])

        if st.button("✅ Register"):
            if student_id <= 0:
                st.error("Please enter a valid Student ID.")
                return

            # Combine leader and members for the transaction
            all_students = [student_id] + member_ids
            
            try:
                # Use a raw connection/cursor to manage the transaction for atomicity
                cursor = conn.cursor(prepared=True)
                conn.start_transaction() 

                # 1. Insert into Participating_Team
                final_team_name = team_name if reg_for == "Team" else None
                total_members = len(all_students)

                cursor.execute(
                    """
                    INSERT INTO Participating_Team (Event_ID, Team_Name, No_of_Participants)
                    VALUES (%s, %s, %s)
                    """,
                    (event_id, final_team_name, total_members)
                )
                pteam_id = cursor.lastrowid
                
                # 2. Insert all students into PTeam_Members & Registrations
                for stud_id in all_students:
                    if stud_id == 0: continue # Skip if a team member ID was left at 0
                    
                    # Insert into PTeam_Members (T-7: before_pteam_member_insert trigger runs here)
                    cursor.execute(
                        "INSERT INTO PTeam_Members (PTeam_ID, Student_ID) VALUES (%s, %s)",
                        (pteam_id, stud_id)
                    )
                    
                    # Insert into Registrations (T-4 & T-9: before/after_registration_insert triggers run here)
                    cursor.execute(
                        """
                        INSERT INTO Registrations (Reg_For, Reg_Date, Payment_Status, Student_ID, PTeam_ID)
                        VALUES (%s, CURDATE(), %s, %s, %s)
                        """,
                        (event_name, payment_status, stud_id, pteam_id)
                    )
                
                conn.commit()
                msg_list = ["All" if total_members > 1 else "", f"{total_members} members" if total_members > 1 else "Student"]
                st.success(f"🎉 {msg_list[0]} {msg_list[1]} successfully registered for {event_name}.")

            except mysql.connector.Error as e:
                conn.rollback() 
                # Display the error message from the database (often from a trigger SIGNAL)
                st.error(f"❌ Registration failed. Error: {e.msg}")
            
            except Exception as e:
                conn.rollback() 
                st.error(f"❌ An unexpected error occurred: {e}")
                
            finally:
                cursor.close()

    # ======================= CANCEL TAB =======================
    with tabs[1]:
        st.subheader("Cancel Event Registration")
        st.caption("P-2: Cancel Registration (Solo/Team)")
        
        student_id = st.number_input("Enter Student ID to Cancel", min_value=1, step=1, key="cancel_id")

        if st.button("🔍 Fetch Registrations", key="fetch_reg_btn"):
            # Using raw query as the F-11 function was dropped in Functions.sql
            try:
                query = """
                    SELECT r.Registration_ID, e.Event_Name, pt.Team_Name, r.Reg_Date, r.Payment_Status
                    FROM Registrations r
                    LEFT JOIN Participating_Team pt ON r.PTeam_ID = pt.PTeam_ID
                    LEFT JOIN Event e ON pt.Event_ID = e.Event_ID
                    WHERE r.Student_ID = %s
                """
                regs_df = pd.read_sql_query(query, conn, params=(student_id,))
            except Exception as e:
                st.error(f"Error fetching registrations: {e}")
                regs_df = pd.DataFrame()

            if not regs_df.empty:
                # Filter out cancelled registrations
                regs_df = regs_df[regs_df["Payment_Status"] != "Cancelled"]
                st.session_state["regs_df"] = regs_df
                st.dataframe(regs_df, hide_index=True, use_container_width=True)
            else:
                st.info("No active registrations found.")


        if "regs_df" in st.session_state and not st.session_state["regs_df"].empty:
            regs_df = st.session_state["regs_df"]

            # Check if all events are gone from the dataframe after filtering
            if regs_df.empty:
                st.info("No active registrations to cancel.")
                if "regs_df" in st.session_state:
                    del st.session_state["regs_df"] # Clear session state
                return

            # Let student select event to cancel
            selected_event = st.selectbox("Select Event to Cancel", regs_df["Event_Name"].unique().tolist(), key="cancel_event_select")
            
            if selected_event:
                # Ensure we select the row corresponding to the selected event name
                reg_row = regs_df.loc[regs_df["Event_Name"] == selected_event].iloc[0]
                reg_id = int(reg_row["Registration_ID"])
                team_name = reg_row.get("Team_Name")

                st.write(f"**Registration ID:** {reg_id}")
                st.write(f"**Team Name:** {team_name if pd.notna(team_name) and team_name else '— (Solo)'}")
                st.write(f"**Registration Date:** {reg_row['Reg_Date']}") 

                reason = st.text_area("Enter reason for cancellation (optional):", key="cancel_reason")

                # Detect team cancellation 
                is_team_reg = pd.notna(team_name) and team_name.strip() != ""

                if is_team_reg:
                    st.warning(
                        "If you cancel this registration, **the entire team will be unregistered** from this event. This action is irreversible."
                    )
                    confirm = st.checkbox("I understand and want to proceed with team cancellation.", key="confirm_team_cancel")
                    
                    if confirm and st.button("❌ Confirm Team Cancellation", key="team_cancel_btn"):
                        try:
                            # P-2: ProcessCancellation(reg_id_in, reason_in, team_cancel=TRUE)
                            result_df, msg = execute_procedure(conn, "ProcessCancellation", (reg_id, reason, True))
                            if result_df is not None and not result_df.empty:
                                st.success(result_df.iloc[0, 0])
                            else:
                                st.success(msg) # Should usually be a success message from the procedure
                            if "regs_df" in st.session_state:
                                del st.session_state["regs_df"]
                        except Exception as e:
                            st.error(f"❌ Cancellation failed: {e}")
                else:
                    # Solo cancellation
                    if st.button("❌ Cancel Solo Registration", key="solo_cancel_btn"):
                        try:
                            # P-2: ProcessCancellation(reg_id_in, reason_in, team_cancel=FALSE)
                            result_df, msg = execute_procedure(conn, "ProcessCancellation", (reg_id, reason, False))
                            if result_df is not None and not result_df.empty:
                                st.success(result_df.iloc[0, 0])
                            else:
                                st.success(msg) # Should usually be a success message from the procedure
                            if "regs_df" in st.session_state:
                                del st.session_state["regs_df"]
                        except Exception as e:
                            st.error(f"❌ Cancellation failed: {e}")