import pyodbc

conn = pyodbc.connect(
    r"DRIVER={ODBC Driver 18 for SQL Server};"
    r"SERVER=localhost\SQLEXPRESS;"
    r"DATABASE=Test;"
    r"Trusted_Connection=yes;"
    r"TrustServerCertificate=yes;"
)

cursor = conn.cursor()

cursor.execute("SELECT DB_NAME()")
database = cursor.fetchone()

print("Connected database:", database[0])

conn.close()