ZSS PowerShell samples
======================

These scripts allow you to create (and delete) [Zumero][zumero] DBFiles, start (and stop) synching tables, add filters, and add permissions without manual intervention.

They're especially useful when you need to prepare multiple similar tables or databases (e.g. a new table or a new database for each customer).

Note that:

1. These scripts require a 32-bit PowerShell. See notes in the scripts on
   achieving that.
2. These scripts expect ZSS Manager to be installed in the standard location
   (C:\Program Files (x86)\Zumero\ZSS Manager)
3. The scripts are intended as examples; modify WHERE clauses, default
   permissions, etc. as you see fit
4. The Common Parameters below can be given defaults to match your needs by
   editing the scripts.

Common parameters:
------------------

### PrimaryDBName
Name of the primary ZSS database

### PrimaryServer
Hostname of the primary ZSS database server

### PrimaryUsername, PrimaryPassword
Optional - if omitted, we just use trusted authentication

### SecondaryDBName
Name of the secondary database where we'll prepare data. 

Optional - defaults to the value of PrimaryDBName. 

Separate databases are only available to ZSS Servers licensed for 
multiple-database use.

### SecondaryServer
Hostname of the secondary database server. 

Optional - defaults to the value of SecondaryServer.

### SecondaryUsername, SecondaryPassword
Optional - if omitted, we just use trusted authentication

By default, if -PrimaryUsername and -PrimaryPassword are specified, the same
values are used for secondary auth (if we're not using trusted auth)


create-dbfile.ps1 DBFile [common parameters]
--------------------------------------------

Creates the DBFile.

prepare-table.ps1 DBFile TableName [common parameters]
------------------------------------------------------

Prepares the table `TableName` for sync within DBFile, and grants full table permissions to Any Authenticated User.


unprepare-table.ps1 DBFile TableName [common parameters]
--------------------------------------------------------

Unprepares `TableName` in `DBFile`


delete-dbfile.ps1 DBFile [common parameters]
--------------------------------------------

Deletes the specified DBFile.  You'll need to unprepare all tables within this DBFile, first.


add-user-perm.ps1 DBFile TableName Username Password [common parameters]
------------------------------------------------------------------------

Grants full access to `TableName` to the user identified by `Username` and
`Password`. Adds the user if necessary.


add-table-filter.ps1 DBFile TableName [-Excludes "col1,col2=default,..."] [common parameters]
---------------------------------------------------------

Adds a simple filter WHERE clause to `TableName`, for Any Authenticated User.
The example filters on a [name] column matching ZUMERO_USER_NAME.

The optional `-Excludes` parameter takes a quoted, comma-separated list of column names to exclude. A column name followed by `=something` will get "something" as a default value for the excluded column; otherwise no default will be set. 


migrate-dbfile.ps1 DBFile SourcePrimaryServer SourcePrimaryDBName DestPrimaryServer DestPrimaryDBName [...]
---------------------------------------------------------

Migrate a DBFile's configuration from one ZSS Server database to another.




[zumero]: http://zumero.com/
