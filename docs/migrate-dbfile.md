# .\migrate-dbfile.ps1
## SYNOPSIS
Migrate a DBFile from one Zumero server to another

## SYNTAX
```powershell
.\migrate-dbfile.ps1 [-DBFile] <String> [-SourcePrimaryServer] <String> [-SourcePrimaryDBName] <String> [-DestPrimaryServer] <String> [-DestPrimaryDBName] <String> [-SourcePrimaryUsername <String>] [-SourcePrimaryPassword <String>] [-DestPrimaryUsername <String>] [-DestPrimaryPassword <String>] [-SourceSecondaryServer <String>] [-SourceSecondaryDBName <String>] [-DestSecondaryServer <String>] [-DestSecondaryDBName <String>] 

[-SourceSecondaryUsername <String>] [-SourceSecondaryPassword <String>] [-DestSecondaryUsername <String>] [-DestSecondaryPassword <String>] [-SkipUsers] [-ScramblePasswords] [-DryRun] [<CommonParameters>]
```

## DESCRIPTION
Given a DBFile name, a source host/database, and a destination host/database,
this script attempts to migrate the DBFile (prepared tables, filters, etc.)
from source to destination.

If either source or destination is a multi-database setup, optional secondary host(s) and
database(s) may be specified.

## PARAMETERS
### -DBFile &lt;String&gt;
The name of the DBFile to migrate. Must exist in the source database, cannot already exist in the destination.
```
Required?                    true
Position?                    2
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SourcePrimaryServer &lt;String&gt;
The hostname or address of the source SQL server.
```
Required?                    true
Position?                    3
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SourcePrimaryDBName &lt;String&gt;
The name of the source ZSS database (the "primary" database specified in the ZSS configuration)
```
Required?                    true
Position?                    4
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -DestPrimaryServer &lt;String&gt;
The hostname or address of the destination SQL server.
```
Required?                    true
Position?                    5
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -DestPrimaryDBName &lt;String&gt;
The name of the destination ZSS database
```
Required?                    true
Position?                    6
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SourcePrimaryUsername &lt;String&gt;
The SQL Server username for the source primary database. If omitted, use Trusted Authentication.
```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SourcePrimaryPassword &lt;String&gt;
The SQL Server password for the source primary database. If omitted, use Trusted Authentication.
```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -DestPrimaryUsername &lt;String&gt;
The SQL Server username for the destination primary database. If omitted, use Trusted Authentication.
```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -DestPrimaryPassword &lt;String&gt;
The SQL Server password for the destination primary database. If omitted, use Trusted Authentication.
```
Required?                    false
Position?                    named
Default value
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SourceSecondaryServer &lt;String&gt;
The hostname or address of the "secondary" SQL server, containing your application's tables.

Defaults to the value of SourcePrimaryServer
```
Required?                    false
Position?                    named
Default value                $SourcePrimaryServer
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SourceSecondaryDBName &lt;String&gt;
The name of the secondary ZSS database

Defaults to the value of SourcePrimaryDBName
```
Required?                    false
Position?                    named
Default value                $SourcePrimaryDBName
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -DestSecondaryServer &lt;String&gt;
The hostname or address of the destination "secondary" SQL server.

Defaults to the value of DestPrimaryServer
```
Required?                    false
Position?                    named
Default value                $DestPrimaryServer
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -DestSecondaryDBName &lt;String&gt;
The name of the "secondary" destination database

Defaults to the value of DestPrimaryDBName
```
Required?                    false
Position?                    named
Default value                $DestPrimaryDBName
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SourceSecondaryUsername &lt;String&gt;
The SQL Server username for the source secondary database

Defaults to the value of SourcePrimaryUsername
```
Required?                    false
Position?                    named
Default value                $SourcePrimaryUsername
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SourceSecondaryPassword &lt;String&gt;
The SQL Server password for the source secondary database

Defaults to the value of SourcePrimaryPassword
```
Required?                    false
Position?                    named
Default value                $SourcePrimaryPassword
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -DestSecondaryUsername &lt;String&gt;
The SQL Server username for the destination secondary database

Defaults to the value of DestPrimaryUsername
```
Required?                    false
Position?                    named
Default value                $DestPrimaryUsername
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -DestSecondaryPassword &lt;String&gt;
The SQL Server password for the destination secondary database

Defaults to the value of DestPrimaryPassword
```
Required?                    false
Position?                    named
Default value                $DestPrimaryPassword
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -SkipUsers &lt;SwitchParameter&gt;
Don't attempt to migrate users in the zumero.users table (or their permissions)
```
Required?                    false
Position?                    named
Default value                False
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -ScramblePasswords &lt;SwitchParameter&gt;
If migrating zumero.users, randomize the users' passwords along the way.
```
Required?                    false
Position?                    named
Default value                False
Accept pipeline input?       false
Accept wildcard characters?  false
```
 
### -DryRun &lt;SwitchParameter&gt;
List any migration warnings or errors, but don't actually attempt migration.
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
PS C:\>migrate-dbfile.ps1 mydbfilename my.server sourcedb -DestPrimaryServer my.server -DestPrimaryDBName destdb

```
Migrates a single-server DBFile to another single server ZSS database, all on my.server, using Windows Authentication.
 
### EXAMPLE 2
```powershell
PS C:\>migrate-dbfile.ps1 mydbfilename my.server sourcedb -DestPrimaryServer elsewhere -DestPrimaryDBName destdb -DestSecondaryServer elsewhere -DestSecondaryDBName otherdb -DestPrimaryUsername sa -DestPrimaryPassword 1234secret!

```
Migrates a single-server DBFile to multipl-server ZSS setup, using SQL authentication on the remote end.
 
### EXAMPLE 3
```powershell
PS C:\>migrate-dbfile.ps1 mydbfilename my.server sourcedb -DestPrimaryServer elsewhere -DestPrimaryDBName destdb -DestSecondaryServer elsewhere -DestSecondaryDBName otherdb -DestPrimaryUsername sa -DestPrimaryPassword 1234secret! -DryRun

```
Checks a migration for errors and warnings without actually modifying anything.

