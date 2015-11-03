# .\prepare-table.ps1
## SYNOPSIS
Prepare a table for synching with ZSS.

## SYNTAX
```powershell
.\prepare-table.ps1 [-DBFile] <String> [-TableName] <String> -PrimaryDBName <String> -PrimaryServer <String> [-PrimaryUsername <String>] [-PrimaryPassword <String>] [-SecondaryDBName <String>] [-SecondaryServer <String>] [-SecondaryUsername <String>] [-SecondaryPassword <String>] [-NoAuth <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Prepares a table for sync. All sync-able columns in the table will be included. Use add-table-filter.ps1
to exclude columns from sync.

By default, all authenticated users are granted full permission to sync this table. Comment out or
modify the Grant-Permissions call if this is not desired behavior.

## PARAMETERS
### -DBFile &lt;String&gt;
The name of the DBFile to which this table will belong.  This DBFile must already exist.
```
Required?                    true
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -TableName &lt;String&gt;
The SQL Server table to be synched.
```
Required?                    true
Position?                    3
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
The SQL Server database containing the table to be synched (on Zumero Servers licensed to sync from multiple databases)

Defaults to the value of PrimaryDBName
```
Required?                    false
Position?                    named
Default value                $PrimaryDBName
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SecondaryServer &lt;String&gt;
The machine name, instance or IP address of the SQL Server hosting containing the table to be synched

Defaults to the value of PrimaryServer
```
Required?                    false
Position?                    named
Default value                $PrimaryServer
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SecondaryUsername &lt;String&gt;
The SQL Server username used when connecting to the Secondary database.

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
 
### -NoAuth &lt;Boolean&gt;
Skip the automatic addition of full permission to all authenticated users.

Defaults to False (add permissions by default)
```
Required?                    false
Position?                    named
Default value                False
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
PS C:\>.\prepare-table.ps1 salesdata Invoices -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server

```
Prepare the [Invoices] table to sync as part of the salesdata DBFile, in a single-database
configuration on my.server, in the dbSales database. Windows Authentication will be used.
 
### EXAMPLE 2
```powershell
PS C:\>.\prepare-table.ps1 salesdata Invoices -PrimaryDBName zssconfig -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server -PrimaryUsername sa -PrimaryPassword sapassword

```
Prepare the [Invoices] table to sync as part of the salesdata DBFile, in a multi-database
configuration on my.server. Log in as 'sa'.

