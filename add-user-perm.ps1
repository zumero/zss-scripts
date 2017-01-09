<#
 .SYNOPSIS
   Grant permissions to a ZSS user.

 .DESCRIPTION
   Grants a given user full access to a synched table. Adds the user if necessary.

 .PARAMETER DBFile
   The name of the DBFile to which this table belongs.

 .PARAMETER ZumeroUser
   The Zumero username to be updated or created.

 .PARAMETER ZumeroPassword
   The password to be used by this user.

 .PARAMETER TableName
   The SQL Server table to be accessed. Omit this to add permissions for this user on ANY prepared table.

 .PARAMETER PrimaryDBName
   The SQL Server database to which your ZSS Server connects, a.k.a the Primary database.

 .PARAMETER PrimaryServer
   The machine name, instance or IP address of the SQL Server hosting the Primary database.

 .PARAMETER PrimaryUsername
   The SQL Server username used when connecting to the Primary database. If omitted, use Trusted Authentication.

 .PARAMETER PrimaryPassword
   The SQL Server password used when connecting to the Primary database. If omitted, use Trusted Authentication.

 .PARAMETER SecondaryDBName
   The SQL Server database containing the table (on Zumero Servers licensed to sync from multiple databases)

   Defaults to the value of PrimaryDBName

 .PARAMETER SecondaryServer
   The machine name, instance or IP address of the SQL Server hosting containing the table

   Defaults to the value of PrimaryServer

 .PARAMETER SecondaryUsername
   The SQL Server username used when connecting to the Secondary database

   Defaults to the value of PrimaryUsername

 .PARAMETER SecondaryPassword
   The SQL Server password used when connecting to the Secondary database.

   Defaults to the value of PrimaryPassword

 .INPUTS
   None

 .OUTPUTS
   None

 .NOTES
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

 .EXAMPLE
   .\add-user-perm.ps1 salesdata zuser zpassword -TableName Invoices -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server
        
   DESCRIPTION
   -----------
   Gives the user "zuser" (with password "zpassword") full access to the "Invoices" table in the "salesdata" DBFile.

 .EXAMPLE
   .\add-user-perm.ps1 salesdata zuser zpassword -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server
        
   DESCRIPTION
   -----------
   Gives the user "zuser" (with password "zpassword") full access to any table in the "salesdata" DBFile.
   
 #>
Param(
  [Parameter(Mandatory=$True,Position=1)]
  [string] $DBFile,

  [Parameter(Mandatory=$True,Position=2)]
  [string] $ZumeroUser,

  [Parameter(Mandatory=$True,Position=3)]
  [string] $ZumeroPassword,

  [string] $TableName,

  [Parameter(Mandatory=$True)]
  [string] $PrimaryDBName,
  [Parameter(Mandatory=$True)]
  [string] $PrimaryServer,
  [string] $PrimaryUsername,
  [string] $PrimaryPassword,
  [string] $SecondaryDBName = $PrimaryDBName,
  [string] $SecondaryServer = $PrimaryServer,
  [string] $SecondaryUsername = $PrimaryUsername,
  [string] $SecondaryPassword = $PrimaryPassword
)

$ErrorActionPreference = "Stop"

if ([Environment]::Is64BitProcess)
{
    "This script must be run from a 32-bit Powershell environment."
    Exit
}

if (! $PSScriptRoot) {
  $PSScriptRoot = split-path -parent $MyInvocation.MyCommand.Definition
}
. "$PSScriptRoot\z-common.ps1"

$ZssManagerPath = [System.IO.Path]::GetFullPath("C:\Program Files (x86)\Zumero\ZSS Manager")
$env:Path += ";" + $ZssManagerPath + "/x86"
[Reflection.Assembly]::LoadFrom($ZssManagerPath + "\ZssManagerLib.dll") | Out-Null

$ConnString = getConnString "primary" $PrimaryServer $PrimaryDBName $PrimaryUsername $PrimaryPassword
$pdb = [Zumero.ZumerifyLib.DB.ZPrimaryDatabase]::Create(0, $ConnString, $ZssManagerPath + "\DB\SqlServer")

$ConnString = getConnString "secondary" $SecondaryServer $SecondaryDBName $SecondaryUsername $SecondaryPassword
$db =  [Zumero.ZumerifyLib.DB.ZDatabase]::Create(0, $pdb, $ConnString, $ZssManagerPath + "\DB\SqlServer")

Function Grant-Permission($dbfile_name, $table_name, $username, $pass)
{
    $db.Open()

    if (! $db.UserTableExists())
    {
      $db.CreateUserTable();
    }

    "Granting permissions for " + $username
    $userpermission = $db.GetUserPermissions($dbfile_name, $username)

    if ($table_name)
    {
      $table = $db.GetHostTable($table_name)
      $userpermission.Table = $table.ObjectId
    }

    $userpermission.ExplicitPull = "Allow"
    $userpermission.ExplicitAdd = "Allow"
    $userpermission.ExplicitMod = "Allow"
    $userpermission.ExplicitDel = "Allow"
    $userpermission.CommitToDB($username, $pass);
    $db.Close()
}

Grant-Permission $DBFile $TableName $ZumeroUser $ZumeroPassword
