# .\delete-dbfile.ps1
## SYNOPSIS
Delete a DBFile from a ZSS Server configuration.

## SYNTAX
```powershell
.\delete-dbfile.ps1 [-DBFile] <String> -PrimaryDBName <String> -PrimaryServer <String> [-PrimaryUsername <String>] [-PrimaryPassword <String>] [-SecondaryDBName <String>] [-SecondaryServer <String>] [-SecondaryUsername <String>] [-SecondaryPassword <String>] [<CommonParameters>]
```

## DESCRIPTION
Deletes the DBFile definition and associated scripts. Assumes all tables within the DBFile
have already been un-prepared (see unprepare-table.ps1).

## PARAMETERS
### -DBFile &lt;String&gt;
The name of the DBFile being deleted.
```
Required?                    true
Position?                    2
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
The SQL Server database containing the DBFile and its tables (on Zumero Servers licensed to sync from multiple databases)

Defaults to the value of PrimaryDBName
```
Required?                    false
Position?                    named
Default value                $PrimaryDBName
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SecondaryServer &lt;String&gt;
The machine name, instance or IP address of the SQL Server hosting containing the DBFile and its tables

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
PS C:\>.\delete-dbfile.ps1 salesdata -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server

```
Delete the "salesdata" DBFile from the dbSales database on my.server. Windows Authentication will be used.
 
### EXAMPLE 2
```powershell
PS C:\>.\delete-dbfile.ps1 salesdata -PrimaryDBName zssconfig -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server -PrimaryUsername sa -PrimaryPassword sapassword

```
Delete the "salesdata" DBFile from the ZSS Server configuration on my.server::zssconfig, and remove its
housekeeping data and triggers from my.server::dbSales. Log in as 'sa'.

