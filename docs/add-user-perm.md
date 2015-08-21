# .\add-user-perm.ps1
## SYNOPSIS
Grant permissions to a ZSS user.

## SYNTAX
```powershell
.\add-user-perm.ps1 [-DBFile] <String> [-ZumeroUser] <String> [-ZumeroPassword] <String> [-TableName <String>] -PrimaryDBName <String> -PrimaryServer <String> [-PrimaryUsername <String>] [-PrimaryPassword <String>] [-SecondaryDBName <String>] [-SecondaryServer <String>] [-SecondaryUsername <String>] [-SecondaryPassword <String>] [<CommonParameters>]
```

## DESCRIPTION
Grants a given user full access to a synched table. Adds the user if necessary.

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
 
### -ZumeroUser &lt;String&gt;
The Zumero username to be updated or created.
```
Required?                    true
Position?                    3
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -ZumeroPassword &lt;String&gt;
The password to be used by this user.
```
Required?                    true
Position?                    4
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -TableName &lt;String&gt;
The SQL Server table to be accessed. Omit this to add permissions for this user on ANY prepared table.
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
PS C:\>.\add-user-perm.ps1 salesdata zuser zpassword -TableName Invoices -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server

```
Gives the user "zuser" (with password "zpassword") full access to the "Invoices" table in the "salesdata" DBFile.
 
### EXAMPLE 2
```powershell
PS C:\>.\add-user-perm.ps1 salesdata zuser zpassword -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server

```
Gives the user "zuser" (with password "zpassword") full access to any table in the "salesdata" DBFile.

