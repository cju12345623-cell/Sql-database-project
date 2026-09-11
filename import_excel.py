import pandas as pd
from sqlalchemy import create_engine
from urllib.parse import quote_plus


# SQL Server 연결
connection_string = quote_plus(
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "DATABASE=Test;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

engine = create_engine(
    f"mssql+pyodbc:///?odbc_connect={connection_string}"
)


# ==============================
# 1. Historical
# ==============================

historical_file = r"31082026HistoricalData-with ReworkPartner.xlsx"

historical = pd.read_excel(
    historical_file,
    sheet_name=0
)

historical["Vlink"] = historical["Vlink"].astype("string")
historical["MSDProjectID"] = historical["MSDProjectID"].astype("string")

historical.to_sql(
    name="Historical",
    con=engine,
    schema="raw",
    if_exists="replace",
    index=False,
    chunksize=1000
)

print(f"Historical imported: {len(historical)} rows")


# ==============================
# 2. Carveout
# ==============================

carveout_file = r"Carveout_Signing_CutoffDate_20260430 2.xlsx"

carveout = pd.read_excel(
    carveout_file,
    sheet_name=0
)

carveout.to_sql(
    name="Carveout",
    con=engine,
    schema="raw",
    if_exists="replace",
    index=False,
    chunksize=1000
)

print(f"Carveout imported: {len(carveout)} rows")


# ==============================
# 3. Tickets
# ==============================

tickets_file = r"all_tickets_17082026.xlsx"

tickets = pd.read_excel(
    tickets_file,
    sheet_name="Archive 2026-08-17"
)

tickets.to_sql(
    name="Tickets",
    con=engine,
    schema="raw",
    if_exists="replace",
    index=False,
    chunksize=1000
)

print(f"Tickets imported: {len(tickets)} rows")


print()
print("==============================")
print("All imports completed!")
print("==============================")

from sqlalchemy import text

with engine.begin() as conn:
    conn.execute(text("EXEC dbo.RefreshCurrentData"))

print("CurrentData refreshed!")