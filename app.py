import sqlite3

conn = sqlite3.connect('ar.database.db')
print("Database connected!")
conn.close()
