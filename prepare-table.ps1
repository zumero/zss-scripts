<#
 .SYNOPSIS
   Prepare a table for synching with ZSS.
 
 .DESCRIPTION
   Prepares a table for sync. All sync-able columns in the table will be included. Use add-table-filter.ps1
   to exclude columns from sync.

   By default, all authenticated users are granted full permission to sync this table. Comment out or
   modify the Grant-Permissions call if this is not desired behavior.

 .PARAMETER DBFile
   The name of the DBFile to which this table will belong.  This DBFile must already exist.

 .PARAMETER TableName
   The SQL Server table to be synched.

 .PARAMETER PrimaryDBName
   The SQL Server database to which your ZSS Server connects, a.k.a the Primary database.

 .PARAMETER PrimaryServer
   The machine name, instance or IP address of the SQL Server hosting the Primary database.

 .PARAMETER PrimaryUsername
   The SQL Server username used when connecting to the Primary database. If omitted, use Trusted Authentication.

 .PARAMETER PrimaryPassword
   The SQL Server password used when connecting to the Primary database. If omitted, use Trusted Authentication.

 .PARAMETER SecondaryDBName
   The SQL Server database containing the table to be synched (on Zumero Servers licensed to sync from multiple databases)

   Defaults to the value of PrimaryDBName

 .PARAMETER SecondaryServer
   The machine name, instance or IP address of the SQL Server hosting containing the table to be synched

   Defaults to the value of PrimaryServer

 .PARAMETER SecondaryUsername
   The SQL Server username used when connecting to the Secondary database.

   Defaults to the value of PrimaryUsername

 .PARAMETER SecondaryPassword
   The SQL Server password used when connecting to the Secondary database.

   Defaults to the value of PrimaryPassword
 
 .PARAMETER NoAuth
   Skip the automatic addition of full permission to all authenticated users.

   Defaults to False (add permissions by default)

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
   .\prepare-table.ps1 salesdata Invoices -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server
        
   DESCRIPTION
   -----------
   Prepare the [Invoices] table to sync as part of the salesdata DBFile, in a single-database
   configuration on my.server, in the dbSales database. Windows Authentication will be used.
   
 .EXAMPLE
   .\prepare-table.ps1 salesdata Invoices -PrimaryDBName zssconfig -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server -PrimaryUsername sa -PrimaryPassword sapassword
        
   DESCRIPTION
   -----------
   Prepare the [Invoices] table to sync as part of the salesdata DBFile, in a multi-database
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

  [string] $SecondaryDBName = $PrimaryDBName,
  [string] $SecondaryServer = $PrimaryServer,
  [string] $SecondaryUsername = $PrimaryUsername,
  [string] $SecondaryPassword = $PrimaryPassword,
  [bool] $NoAuth = $false
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
$pdb = [Zumero.ZumerifyLib.DB.ZPrimaryDatabase]::Create(0, $ConnString, $ZssManagerPath + "\DB\SqlServer")

$ConnString = getConnString "secondary" $SecondaryServer $SecondaryDBName $SecondaryUsername $SecondaryPassword
$db =  [Zumero.ZumerifyLib.DB.ZDatabase]::Create(0, $pdb, $ConnString, $ZssManagerPath + "\DB\SqlServer")

Function Prepare-Table($dbfile_name, $table_name)
{
    "Preparing " + $table_name + " in dbfile " + $dbfile_name
    $db.Open()
    # instantiate table to prepare
    $table = $db.GetHostTable($table_name)
    if (!$table.Prepared)
    {
        $whyNot = New-Object 'System.Collections.Generic.List[string]'
        if ($table.CanBePrepared($dbfile_name, [ref]$whyNot))
        {
            # print warnings, if there are any
            if ($table.IncompatibilityWarnings -ne $null)
            {
                foreach ($warning in $table.IncompatibilityWarnings)
                {
        #            "  Warning: " + $warning
                }
            }

            # prepare
            $prepare_script = $table.GetPrepareSqlScript($dbfile_name)
            $db.ExecuteBatchSql($prepare_script)
        }
        else
        {
            $db.Close()
            throw "Unable to prepare table " + $table_name + ": " + [System.String]::Join("; ", $whyNot.ToArray())
        }
    }
    else
    {
        "Table " + $table_name + " is already prepared."
    }
	$db.Close()
}

Function Grant-Permissions($dbfile_name)
{
    # Give permissions to any authenticated user.
    $db.Open()
    $anyUser = [Zumero.ZumerifyLib.DB.ZACL]::UI_WHO_ANY_AUTHENTICATED_USER
    "Granting permissions for " + $anyUser
    $userpermission = $db.GetUserPermissions($dbfile_name, $anyUser)
    $userpermission.Table = $null
    $userpermission.ExplicitPull = "Allow"
    $userpermission.ExplicitAdd = "Allow"
    $userpermission.ExplicitMod = "Allow"
    $userpermission.ExplicitDel = "Allow"
    $userpermission.CommitToDB($anyUser, "")
    $db.Close()
}

Prepare-Table $DBFile $TableName

if (! $NoAuth)
{
    Grant-Permissions($DBFile)
}
