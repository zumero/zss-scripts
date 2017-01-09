<#
 .SYNOPSIS
   Migrate a DBFile from one Zumero server to another

 .DESCRIPTION
   Given a DBFile name, a source host/database, and a destination host/database,
   this script attempts to migrate the DBFile (prepared tables, filters, etc.)
   from source to destination.

   If either source or destination is a multi-database setup, optional secondary host(s) and
   database(s) may be specified.

 .PARAMETER DBFile
   The name of the DBFile to migrate. Must exist in the source database, cannot already exist in the destination.

 .PARAMETER SourcePrimaryServer
   The hostname or address of the source SQL server.

 .PARAMETER SourcePrimaryDBName
   The name of the source ZSS database (the "primary" database specified in the ZSS configuration)

 .PARAMETER DestPrimaryServer
   The hostname or address of the destination SQL server.

 .PARAMETER DestPrimaryDBName
   The name of the destination ZSS database

 .PARAMETER SourcePrimaryUsername
   The SQL Server username for the source primary database. If omitted, use Trusted Authentication.

 .PARAMETER SourcePrimaryPassword
   The SQL Server password for the source primary database. If omitted, use Trusted Authentication.

 .PARAMETER SourceSecondaryServer 
   The hostname or address of the "secondary" SQL server, containing your application's tables.

   Defaults to the value of SourcePrimaryServer

 .PARAMETER SourceSecondaryDBName 
   The name of the secondary ZSS database

   Defaults to the value of SourcePrimaryDBName

 .PARAMETER DestSecondaryServer 
   The hostname or address of the destination "secondary" SQL server.

   Defaults to the value of DestPrimaryServer

 .PARAMETER DestSecondaryDBName 
   The name of the "secondary" destination database

   Defaults to the value of DestPrimaryDBName

 .PARAMETER SourceSecondaryUsername 
   The SQL Server username for the source secondary database

   Defaults to the value of SourcePrimaryUsername

 .PARAMETER SourceSecondaryPassword 
   The SQL Server password for the source secondary database

   Defaults to the value of SourcePrimaryPassword

 .PARAMETER DestPrimaryUsername
   The SQL Server username for the destination primary database. If omitted, use Trusted Authentication.

 .PARAMETER DestPrimaryPassword
   The SQL Server password for the destination primary database. If omitted, use Trusted Authentication.

 .PARAMETER DestSecondaryUsername 
   The SQL Server username for the destination secondary database

   Defaults to the value of DestPrimaryUsername

 .PARAMETER DestSecondaryPassword 
   The SQL Server password for the destination secondary database

   Defaults to the value of DestPrimaryPassword

 .PARAMETER DryRun
   List any migration warnings or errors, but don't actually attempt migration.

 .PARAMETER SkipUsers
   Don't attempt to migrate users in the zumero.users table (or their permissions)

 .PARAMETER ScramblePasswords
   If migrating zumero.users, randomize the users' passwords along the way.

 .INPUTS
   None

 .OUTPUTS
   None

 .EXAMPLE
   migrate-dbfile.ps1 mydbfilename my.server sourcedb -DestPrimaryServer my.server -DestPrimaryDBName destdb

   DESCRIPTION
   -----------
   Migrates a single-server DBFile to another single server ZSS database, all on my.server, using Windows Authentication.

 .EXAMPLE
   migrate-dbfile.ps1 mydbfilename my.server sourcedb -DestPrimaryServer elsewhere -DestPrimaryDBName destdb -DestSecondaryServer elsewhere -DestSecondaryDBName otherdb -DestPrimaryUsername sa -DestPrimaryPassword 1234secret!

   DESCRIPTION
   -----------
   Migrates a single-server DBFile to multipl-server ZSS setup, using SQL authentication on the remote end.

 .EXAMPLE
   migrate-dbfile.ps1 mydbfilename my.server sourcedb -DestPrimaryServer elsewhere -DestPrimaryDBName destdb -DestSecondaryServer elsewhere -DestSecondaryDBName otherdb -DestPrimaryUsername sa -DestPrimaryPassword 1234secret! -DryRun

   DESCRIPTION
   -----------
   Checks a migration for errors and warnings without actually modifying anything.

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
 #>

  Param(
  [Parameter(Mandatory=$True,Position=1)]
  [string] $DBFile,

  [Parameter(Mandatory=$True,Position=2)]
  [string] $SourcePrimaryServer,
  [Parameter(Mandatory=$True,Position=3)]
  [string] $SourcePrimaryDBName,

  [Parameter(Mandatory=$True,Position=4)]
  [string] $DestPrimaryServer,
  [Parameter(Mandatory=$True,Position=5)]
  [string] $DestPrimaryDBName,

  [string] $SourcePrimaryUsername,
  [string] $SourcePrimaryPassword,
  [string] $DestPrimaryUsername,
  [string] $DestPrimaryPassword,

  [string] $SourceSecondaryServer = $SourcePrimaryServer,
  [string] $SourceSecondaryDBName = $SourcePrimaryDBName,

  [string] $DestSecondaryServer = $DestPrimaryServer,
  [string] $DestSecondaryDBName = $DestPrimaryDBName,

  [string] $SourceSecondaryUsername = $SourcePrimaryUsername,
  [string] $SourceSecondaryPassword = $SourcePrimaryPassword,

  [string] $DestSecondaryUsername = $DestPrimaryUsername,
  [string] $DestSecondaryPassword = $DestPrimaryPassword,

  [switch] $SkipUsers = $FALSE,
  [switch] $ScramblePasswords = $FALSE,

  [switch] $DryRun = $FALSE
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

  $ConnString = getConnString "source primary" $SourcePrimaryServer $SourcePrimaryDBName $SourcePrimaryUsername $SourcePrimaryPassword
  $srcpdb = [Zumero.ZumerifyLib.DB.ZPrimaryDatabase]::Create(0, $ConnString, $ZssManagerPath + "\DB\SqlServer")

  $ConnString = getConnString "source secondary" $SourceSecondaryServer $SourceSecondaryDBName $SourceSecondaryUsername $SourceSecondaryPassword
  $srcdb =  [Zumero.ZumerifyLib.DB.ZDatabase]::Create(0, $srcpdb, $ConnString, $ZssManagerPath + "\DB\SqlServer")

  $ConnString = getConnString "destinaton primary" $DestPrimaryServer $DestPrimaryDBName $DestPrimaryUsername $DestPrimaryPassword
  $dstpdb = [Zumero.ZumerifyLib.DB.ZPrimaryDatabase]::Create(0, $ConnString, $ZssManagerPath + "\DB\SqlServer")

  $ConnString = getConnString "destinaton secondary" $DestSecondaryServer $DestSecondaryDBName $DestSecondaryUsername $DestSecondaryPassword
  $dstdb =  [Zumero.ZumerifyLib.DB.ZDatabase]::Create(0, $dstpdb, $ConnString, $ZssManagerPath + "\DB\SqlServer")

  $srcpdb.Open()
  $srcdb.Open()

  $dstpdb.Open()
  $dstdb.Open()

  $mig = [Zumero.ZumerifyLib.DB.ZMigration]::Create(0, $srcpdb, $srcdb, $dstpdb, $dstdb, $DBFile)

  $errs = $mig.Errors

  if ($DryRun)
  {
  "Dry run"
  }

  if ($errs.Count -gt 0)
  {
  "Errors:"
  ""
  $errs
  ""

  if ($mig.Warnings -gt 0)
  {
    "Warnings: "
    ""
    $mig.Warnings
    ""
  }
  }
  else
  {
  if ($DryRun)
  {
    if ($mig.Warnings -gt 0)
    {
      "Warnings: "
      ""
      $mig.Warnings
      ""
    }
    else
    {
      "No warnings or errors."
    }
  }
  else
  {
    $mig.MigrateUsers = ! $SkipUsers
    $mig.FuzzPasswords = $ScramblePasswords

    if ($mig.Migrate())
    {
      ""
      "Migration succeeded."
    }
    else
    {
      "Errors: "
      $mig.Errors
    }
  }
  }

  $dstdb.Close()
  $dstpdb.Close()
  $srcdb.Close()
  $srcpdb.Close()
