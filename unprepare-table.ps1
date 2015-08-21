<#
 .SYNOPSIS
   Stop synching a table with ZSS.
 
 .DESCRIPTION
   Removes a table from a DBFile, along with housekeeping and history information associated with the table.
   The DBFile, and the actual table data, are left intact.

 .PARAMETER DBFile
   The name of the DBFile to which this table belongs.

 .PARAMETER TableName
   The SQL Server table to be removed from sync.

 .PARAMETER PrimaryDBName
   The SQL Server database to which your ZSS Server connects, a.k.a the Primary database.

 .PARAMETER PrimaryServer
   The machine name, instance or IP address of the SQL Server hosting the Primary database.

 .PARAMETER PrimaryUsername
   The SQL Server username used when connecting to the Primary database. If omitted, use Trusted Authentication.

 .PARAMETER PrimaryPassword
   The SQL Server password used when connecting to the Primary database. If omitted, use Trusted Authentication.

 .PARAMETER SecondaryDBName
   The SQL Server database containing the table to be un-prepared (on Zumero Servers licensed to sync from multiple databases)

   Defaults to the value of PrimaryDBName

 .PARAMETER SecondaryServer
   The machine name, instance or IP address of the SQL Server hosting containing the table to be un-prepared

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
   .\unprepare-table.ps1 salesdata Invoices -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server
        
   DESCRIPTION
   -----------
   Remove the [Invoices] table from the salesdata DBFile, in a single-database
   configuration on my.server, in the dbSales database. Windows Authentication will be used.
   
 .EXAMPLE
   .\unprepare-table.ps1 salesdata Invoices -PrimaryDBName zssconfig -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server -PrimaryUsername sa -PrimaryPassword sapassword
        
   DESCRIPTION
   -----------
   Remove the [Invoices] table from the salesdata DBFile, in a multi-database
   configuration on my.server. Log in as 'sa'.

 #>
Param(
  [Parameter(Mandatory=$True,Position=1)]
  [string] $DBFile,

  [Parameter(Mandatory=$True,Position=2)]
  [string] $TableName,

  [Parameter(Mandatory=$True)]
  [string] $PrimaryDBName,
  [Parameter(Mandatory=$True)]
  [string] $PrimaryServer,
  [string] $PrimaryUsername,
  [string] $PrimaryPassword,

  [string] $SecondaryDBName,
  [string] $SecondaryServer,
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
[Reflection.Assembly]::LoadFrom($ZssManagerPath + "\ZssManagerLib.dll") | Out-Null

$ConnString = getConnString "primary" $PrimaryServer $PrimaryDBName $PrimaryUsername $PrimaryPassword
$pdb = [Zumero.ZumerifyLib.DB.ZPrimaryDatabase]::Create(0, $ConnString)

$ConnString = getConnString "secondary" $SecondaryServer $SecondaryDBName $SecondaryUsername $SecondaryPassword
$db =  [Zumero.ZumerifyLib.DB.ZDatabase]::Create(0, $pdb, $ConnString, $ZssManagerPath + "\DB\SqlServer")

Function Unprepare-Table($dbfile_name, $table_name)
{
    "Un-preparing " + $table_name + " in dbfile " + $dbfile_name

    $db.Open()
    # instantiate table to prepare
    $table = $db.GetHostTable($table_name)

    if ($table.Prepared)
    {
        if ($table.PreparedDbFile -ne $dbfile_name)
        {
            "Unable to unprepare table " + $table_name + ": table is prepared for dbfile " + $table.PreparedDbFile
        }
        else
        {
            $whyNot = New-Object 'System.Collections.Generic.List[string]'
            if ($table.CanBeUnprepared($dbfile_name, [ref]$whyNot))
            {
                $unprepare_script = $table.GetUnprepareSqlScript($dbfile_name)
                $db.ExecuteBatchSql($unprepare_script)
            }
            else
            {
                "Unable to unprepare table " + $table_name + ": " + [System.String]::Join("; ", $whyNot.ToArray())
            }
        }
    }
    else
    {
        $table_name + " is not prepared."
    }

	$db.Close()
}

Unprepare-Table $DBFile $TableName
