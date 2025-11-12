import streamlit as st
import pandas as pd

def dashboard_page(conn, execute_procedure, execute_function):
    """Main Dashboard for overview metrics and reports."""
    st.title("🏛️ Campus Event Management")
    
    # Fetch future events
    df_events, error = execute_procedure(conn, "GetFutureEvents")
    if error != "Success" or df_events.empty:
        st.error(f"⚠️ Unable to load events: {error}")
        return

    # Create display column for dropdown
    df_events["Display"] = df_events["Event_Name"] + " (ID: " + df_events["Event_ID"].astype(str) + ")"

    # Overview Metrics
    col1, col2, col3 = st.columns(3)
    upcoming_count = execute_function(conn, "GetUpcomingEventCount()")
    col1.metric("Upcoming Events", f"{upcoming_count} 🎉")
    
    # Event selection dropdown over col2, col3
    with st.container():
        cols = st.columns([1.5, 2.3, 1])
        with cols[1]: 
            selected_event = st.selectbox("Select Event to View Details 📝", df_events["Display"], key='event_dropdown')

    selected_event_id = df_events.loc[df_events["Display"] == selected_event, "Event_ID"].iloc[0]

    # Fetch dynamic metrics based on event selection
    total_regs = execute_function(conn, f"GetTotalRegistrations({selected_event_id})")
    avg_rating = execute_function(conn, f"GetAvgEventRating({selected_event_id})")

    col2.metric("Total Registrations", f"{total_regs or 0} 👥")
    if avg_rating is not None and avg_rating >= 0:
        col3.metric("Avg. Rating", f"{avg_rating:.2f} ⭐")
    else:
        col3.metric("Avg. Rating", "N/A")

    st.markdown("---")

    # Upcoming Events Table
    st.subheader("📅 Upcoming Events Schedule")

    if isinstance(df_events, pd.DataFrame) and not df_events.empty:
        st.dataframe(df_events, hide_index=True, use_container_width=True)
    else:
        st.info("No upcoming events available!")

    st.markdown("---")
    
    # View by Date Section
    st.subheader("🔍 View Events By Date")
    
    selected_date = st.date_input("Choose a date to view events")
    if st.button("Load Events for Selected Date"):
        df_events_by_date, error = execute_procedure(conn, "GetEventsForDate", args=(selected_date,))
        if error != "Success":
            st.error(error)
        elif isinstance(df_events_by_date, pd.DataFrame) and not df_events_by_date.empty:
            st.dataframe(df_events_by_date, hide_index=True, use_container_width=True)
        else:
            st.info(f"No events scheduled for {selected_date}!")