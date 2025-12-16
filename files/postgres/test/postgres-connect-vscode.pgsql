

/*
Run the below command to create a new database

source <(curl -s https://raw.githubusercontent.com/radiant-rstats/docker-k8s/refs/heads/main/files/postgres/postgres-createdb.sh)

A lot of output will be generated. If you see a ":" when database creation is done,
press the 'q' key to exit the output.

Add connections for the databases that you will use in the SQL + ETL class.
Make the PostgreSQL Explorer extension visible and click on the + icon to add connections. Use:

127.0.0.1 as the hostname
“jovyan” as the PostgreSQL user
“postgres” as the password
8765 as the port number
Standard connection
“Northwind” as the database
“Northwind” as the display name

Click on the + icon one more time to add the final connection. Use:

127.0.0.1 as the hostname
“jovyan” as the PostgreSQL user
“postgres” as the password
8765 as the port number
Standard connection
“WestCoastImporters” as the database
“WestCoastImporters” as the display name
*/

/*
click on "Select Postgres Server" at the bottom of your VS Code window
and choose rsm-msba and check if any of the below statements work
all queries below are commented out. remove the "--" in front of a
SELECT statement to make it available to run

press F5 or right-click on the editor window and select "Run Query"

what happens when you try to run a query for a table that is in another
database?
*/

-- SELECT * FROM "films" LIMIT 5;

/* choose WestCoastImporter as the active server and check if the below statement works */
-- SELECT * FROM "buyinggroup" LIMIT 5;

/* choose Northwind as the active server and check if the below statement works */
SELECT * FROM "products" LIMIT 5;

/*
make sure you have the PostgreSQL extension for VS Code
installed (by Chris Kolkman)

make sure to "Select Postgres Server" at the bottom
of the VS Code window and then select a server and a database
*/
