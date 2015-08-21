# .\add-table-filter.ps1
## SYNOPSIS
Add a WHERE filter and optional column exclusions to a synched table.

## SYNTAX
```powershell
.\add-table-filter.ps1 [-DBFile] <String> [-TableName] <String> [-Excludes <String>] -PrimaryDBName <String> -PrimaryServer <String> [-PrimaryUsername <String>] [-PrimaryPassword <String>] [-SecondaryDBName <String>] [-SecondaryServer <String>] [-SecondaryUsername <String>] [-SecondaryPassword <String>] [<CommonParameters>]
```

## DESCRIPTION
Adds a simple filter WHERE clause to a TableName, for Any Authenticated User.
The example filters on a [name] column matching ZUMERO_USER_NAME. Edit the script to use a different WHERE clause.

The optional -Excludes parameter takes a quoted, comma-separated list of column names to exclude.

## PARAMETERS
### -DBFile &lt;String&gt;
The name of the DBFile to which this table belongs.
```
Required?                    true
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -TableName &lt;String&gt;

```
Required?                    true
Position?                    3
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -Excludes &lt;String&gt;
A quoted, comma-separated list of column names to exclude. 

A column name followed by `=something` will get "something" as a default value for the excluded column; otherwise no default will be set.
```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -PrimaryDBName &lt;String&gt;
The SQL Server database to which your ZSS Server connects, a.k.a the Primary database.
```
Required?                    true
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -PrimaryServer &lt;String&gt;
The machine name, instance or IP address of the SQL Server hosting the Primary database.
```
Required?                    true
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -PrimaryUsername &lt;String&gt;
The SQL Server username used when connecting to the Primary database. If omitted, use Trusted Authentication.
```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -PrimaryPassword &lt;String&gt;
The SQL Server password used when connecting to the Primary database. If omitted, use Trusted Authentication.
```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SecondaryDBName &lt;String&gt;
The SQL Server database containing the table (on Zumero Servers licensed to sync from multiple databases)

Defaults to the value of PrimaryDBName
```
Required?                    false
Position?                    named
Default value                $PrimaryDBName
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SecondaryServer &lt;String&gt;
The machine name, instance or IP address of the SQL Server hosting containing the table

Defaults to the value of PrimaryServer
```
Required?                    false
Position?                    named
Default value                $PrimaryServer
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SecondaryUsername &lt;String&gt;
The SQL Server username used when connecting to the Secondary database

Defaults to the value of PrimaryUsername
```
Required?                    false
Position?                    named
Default value                $PrimaryUsername
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SecondaryPassword &lt;String&gt;
The SQL Server password used when connecting to the Secondary database.

Defaults to the value of PrimaryPassword
```
Required?                    false
Position?                    named
Default value                $PrimaryPassword
Accept pipeline input?       false
Accept wildcard characters?  false
```

## INPUTS
None

## OUTPUTS
None

## NOTES
This script must be run from a 32-bit Powershell environment.
$ C:\Windows\syswow64\WindowsPowerShell\v1.0\powershell.exe -file thisScript.ps1

In order to load Zumero dlls, powershell must be set up to run against .NET 4
- use powershell 3
- or create this file:

--- C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe.config ---

    <?xml version="1.0"?> 
    <configuration> 
        <startup useLegacyV2RuntimeActivationPolicy="true"> 
        <supportedRuntime version="v4.0.30319"/> 
        <supportedRuntime version="v2.0.50727"/> 
        </startup> 
    </configuration> 

--- C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe.config ---

## EXAMPLES
### EXAMPLE 1
```powershell
PS C:\>.\add-table-filter.ps1 salesdata Invoices -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server

```
Adds a WHERE filter for Any Authenticated User to the Invoices table in the salesdata DBFile.
 
### EXAMPLE 2
```powershell
PS C:\>.\add-table-filter.ps1 salesdata Invoices -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server -Excludes "address,city=Springfield"

```
Adds a WHERE filter for Any Authenticated User to the Invoices table in the salesdata DBFile. 

Excludes the "address" column (with no default) and the "city" column (with a default of "Springfield")
from sync.

