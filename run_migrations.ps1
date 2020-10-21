Param(
## The connection details for the primary SQL Server connection 
## (the database that the Zumero server connects to)
  [Parameter(Mandatory=$True)]
  [string] $SQLServer,
  [Parameter(Mandatory=$True)]
  [string] $SQLDBName,
  
## The optional connection details for the secondary connection
## (the database that contains the tables to sync)
  [string] $SQLServer_Tables,
  [string] $SQLDBName_Tables,

## The username and password are assumed to be identical for both.
## Leave out these parameters to use Windows auth for the current account  
  [string] $SQLUsername,
  [string] $SQLPassword,
  
## True to run all of the table migrations without applying any
## Zumero configuration
  [string] $SkipZumero = $false,

## The Zumero DBFile name. Mandatory, if $SkipZumero is false
  [string] $DBFile,
## If this is true, filters and permissions will be applied to the Anyone 
## group in Zumero. Otherwise, they will apply to Any Authenticated User
  [string] $AllowAnonymous = $false
)
$DoZumero = $SkipZumero -eq $false


## BEGIN BITNESS BUSINESS
## This section meets two requirements.
## * Zumero operations can only happen in a 32bit powershell process
## * If running without performing Zumero operations, the SQL statements go through
##   the SqlServer module, which is 64bit only.
## If either of the situations isn't satisfied, rerun the command line in the appropriate environment
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64" -and $DoZumero -eq $false) {
    if ($myInvocation.Line) {
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
exit $lastexitcode
}

if ([Environment]::Is64BitProcess -and $DoZumero -eq $true) {
if ($myInvocation.Line) {
        &"$env:WINDIR\syswow64\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
        &"$env:WINDIR\syswow64\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
exit $lastexitcode
}
## END BITNESS BUSINESS

## Convert the parameters to more explicit variable names
## For the difference between the two database connection types,
## read https://zumero.com/docs/zumero_for_sql_server_manager.html#multi-db-configuration

#Default secondary connections to the primary, if they haven't been specified.
$SecondaryDBName = If ($SQLDBName_Tables) { $SQLDBName_Tables } Else { $SQLDBName }
$SecondaryServer = If ($SQLServer_Tables) { $SQLServer_Tables } Else { $SQLServer }

$PrimaryDBName = $SQLDBName
$PrimaryServer = $SQLServer
$PrimaryUsername = $SQLUsername
$PrimaryPassword = $SQLPassword
$SecondaryUsername = $SQLUsername
$SecondaryPassword = $SQLPassword

$ErrorActionPreference = "Stop"

if (! $PSScriptRoot) {
  $PSScriptRoot = split-path -parent $MyInvocation.MyCommand.Definition
} 
. "$PSScriptRoot\zumero_scripts\z-common.ps1"
if ($DoZumero -eq $false) {
	if ((Get-Module -ListAvailable -Name SqlServer) -eq $false) {
		Write-Host "Installing SQLServer PowerShell module"
		Install-Module -Name SqlServer -Scope CurrentUser -AllowClobber
	}
	$global:primaryDatabase = $null
	$global:secondaryDatabase = $null
	$global:UseZSSConnection = $false

}
else
{
	if ($PSBoundParameters.ContainsKey('DBFile') -eq $false)
	{
		"If you want to perform Zumero operations, you must provide a DBFile"
		Exit
	}
	$dbs = Open-Database $PrimaryServer $PrimaryDBName $PrimaryUsername $PrimaryPassword $SecondaryServer $SecondaryDBName $SecondaryUsername $SecondaryPassword 
	$global:primaryDatabase = $dbs[0]
	$global:secondaryDatabase = $dbs[1]
	$global:UseZSSConnection = $true
}

$global:primarySQLConnectString = getConnString "primary" $PrimaryServer $PrimaryDBName $PrimaryUsername $PrimaryPassword
$global:secondarySQLConnectString = getConnString "secondary" $SecondaryServer $SecondaryDBName $SecondaryUsername $SecondaryPassword

try
{
	# Create the _MigrationHistory table, which will store a record for every applied migration
	 ExecuteSql-Secondary("if not exists (select * from sysobjects where name='_MigrationHistory' and xtype='U')
    create table _MigrationHistory (migrationId nvarchar(100)  PRIMARY KEY, migrationDate datetime2 DEFAULT GETDATE());
    ")
	Get-ChildItem "$PSScriptRoot\migrations" -Filter *.ps1 | 
	Foreach-Object {
		$performMigration = $false
		try 
		{
			ExecuteSql-Secondary ("INSERT INTO _MigrationHistory (migrationId) VALUES ('" + $_.BaseName + "');");
			$performMigration = $true
		}
		catch
		{
		}
		if ($performMigration -eq $true)
		{
			try
			{
				#This loads and runs the Perform-Upgrade function defined in the ps1 file
				"------ Performing migration " + $_.FullName + " -------"
				. $_.FullName
				Perform-Upgrade $_.BaseName $DBFile $DoZumero $AllowAnonymous
				Function Perform-Upgrade {}
			}
			catch
			{
				throw
			}
		}
	}
	"Migrations completed successfully"
}
catch
{
	Resolve-Error
}
finally
{
	if ($global:UseZSSConnection)
	{
		$global:secondaryDatabase.close();
		$global:primaryDatabase.close();
	}
}
