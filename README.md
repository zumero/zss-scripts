ZSS Powershell migrations
=========================

This set of files is designed to help manage database migrations when using 
Zumero for SQL Server. Included are examples of lots of schema changes, 
including adding tables, adding columns, and changing filters.

Running migrations
==================

When running migrations, you may choose to skip the Zumero steps, for use 
on systems that don't have ZSS Manager installed (like build machines). 
You will be prompted to install the SqlServer Powershell module, if it 
is not already installed.

```
# No zumero operations will be included
.\run_migrations.ps1 -SQLDBName sql_db_name -SQLServer "COMPUTER\INSTANCE" -SkipZumero $true
```

```
# Zumero operations will be included
.\run_migrations.ps1 -SQLDBName sql_db_name -SQLServer "COMPUTER\INSTANCE" -DBFile mydbfile
```

Writing migrations
==================

Migrations are stored in separate files in the migrations directory. There 
are conventions that you should follow:

* Put the date in the filename in the format YYYY_MM_DD_description.ps1. 
  These files are run in the sort order of the filenames. The descriptions 
  will help eliminate the possibility that two developers who started 
  coding their migrations on the same day will conflict.
* By convention, if the SQL to be performed is too unwieldy, put it in 
  a separate file with the same extension. Several example show how to 
  load and execute the SQL from a separate file.

