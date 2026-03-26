#!/bin/bash
# Start SQL Server in background
/opt/mssql/bin/sqlservr &
PID=$!

echo "Waiting for SQL Server to be ready..."
for i in {1..30}; do
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -No -Q "SELECT 1" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "SQL Server is ready."
        break
    fi
    echo "  attempt $i/30..."
    sleep 2
done

echo "Creating database and tables..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -No \
    -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'LaplaceImmo') CREATE DATABASE LaplaceImmo"

/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -No \
    -d LaplaceImmo -i /sql-scripts/Create\ Tables.sql

echo "Database initialized."

wait $PID
