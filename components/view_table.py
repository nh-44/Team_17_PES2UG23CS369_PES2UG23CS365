import streamlit as st
import pandas as pd

def view_table(conn, table_name):
    try:
        # Nautrally guard against SQL injection: allow only known table names
        allowed_tables = {
            "students", "faculty", "venue", "event", "registrations",
            "feedback", "resources", "organising_team", "audit_logs", "grievances",
            "participating_team", "pteam_members", "ot eam_members", "cancellations", "clubs"
        }
        # normalize
        tbl = table_name.strip().lower()
        if tbl not in allowed_tables:
            return None, f"Table '{table_name}' is not allowed for direct viewing."

        query = f"SELECT * FROM {tbl} LIMIT 10000"  # limit to avoid huge loads
        df = pd.read_sql_query(query, conn)
        return df, "Success"
    except Exception as e:
        return None, str(e)

def table_viewer_page(conn):
    st.title("📊 Database Table Viewer")
    st.markdown("Explore tables in Campus Event Management System.")

    tables = ["students", "faculty", "venue", "event", "registrations", "feedback", "resources", "organising_team", "audit_logs", "grievances", "participating_team", "pteam_members", "oTeam_members", "cancellations", "clubs"]
    selected_table = st.selectbox("Select Table", tables)

    if st.button("🔍 View Table Data"):
        df, msg = view_table(conn, selected_table)
        if msg == "Success" and df is not None:
            if df.empty:
                st.info("No rows found in selected table.")
            else:
                st.dataframe(df, use_container_width=True)
                csv = df.to_csv(index=False).encode('utf-8')
                st.download_button("📥 Download CSV", csv, file_name=f"{selected_table}.csv", mime="text/csv")
        else:
            st.error(f"Error fetching data: {msg}")