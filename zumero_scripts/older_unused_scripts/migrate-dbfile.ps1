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

# SIG # Begin signature block
# MIIM/wYJKoZIhvcNAQcCoIIM8DCCDOwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUtgkimcLfRjnpdr1sJoN+f6i
# eBagggo0MIIE0zCCA7ugAwIBAgIQXJkusQrBtsaXJ/F/dxsW+DANBgkqhkiG9w0B
# AQsFADB/MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xHzAdBgNVBAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxMDAuBgNVBAMTJ1N5
# bWFudGVjIENsYXNzIDMgU0hBMjU2IENvZGUgU2lnbmluZyBDQTAeFw0xNTEwMTUw
# MDAwMDBaFw0xODExMTMyMzU5NTlaMGYxCzAJBgNVBAYTAlVTMREwDwYDVQQIEwhJ
# bGxpbm9pczESMBAGA1UEBxMJQ2hhbXBhaWduMRcwFQYDVQQKFA5Tb3VyY2VHZWFy
# IExMQzEXMBUGA1UEAxQOU291cmNlR2VhciBMTEMwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCp99Ht3DuB/7X2M7yT9jNQO37CwjAPzVVY8/CRObbkXCh6
# UBfz22w+/PZ5zOC6CPB72vCrZj58H9jvOTMvwjcWoZP3oj+h8EdsgW3ZAPv0Rsx7
# cMwKQPBkV6Y7ZG3acskg5o+AOKiSxCcBrhVDlgq9OmIHrAGAIx1mUq+6cw5h6xpJ
# Cg4hkzCHoBIXiUPXsTN13TBBwx84YjQuv/WOWUkYE92jLsxebDdD8gxKcNkVTgE4
# DRYR/qBShfhKI/RdN0YVnpEjNif8RfB78+Ii9h44f1dfREA0M9xexl03AOlR+Yf0
# o+xM1oLPT8D0IsBcNyOioa5lwTT+7fXNq5e61bt1AgMBAAGjggFiMIIBXjAJBgNV
# HRMEAjAAMA4GA1UdDwEB/wQEAwIHgDArBgNVHR8EJDAiMCCgHqAchhpodHRwOi8v
# c3Yuc3ltY2IuY29tL3N2LmNybDBmBgNVHSAEXzBdMFsGC2CGSAGG+EUBBxcDMEww
# IwYIKwYBBQUHAgEWF2h0dHBzOi8vZC5zeW1jYi5jb20vY3BzMCUGCCsGAQUFBwIC
# MBkMF2h0dHBzOi8vZC5zeW1jYi5jb20vcnBhMBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MFcGCCsGAQUFBwEBBEswSTAfBggrBgEFBQcwAYYTaHR0cDovL3N2LnN5bWNkLmNv
# bTAmBggrBgEFBQcwAoYaaHR0cDovL3N2LnN5bWNiLmNvbS9zdi5jcnQwHwYDVR0j
# BBgwFoAUljtT8Hkzl699g+8uK8zKt4YecmYwHQYDVR0OBBYEFJgk8fCJfxk9cOJp
# ep6VXu+fHA9fMA0GCSqGSIb3DQEBCwUAA4IBAQCVxEvlupC+aofk5tU9jTOeUMI/
# gbaWvWX9Ck9AO/SBRSnQR2PfnSxCnUyJSA/h2iBErmapHZEPDbLhpJgimRNDy0p5
# qDgS9qQrwPX5pnrDD3cdz1NwqgrSGtHdqfhy3Oavjz2inkRIeievt+UoGhE9IE9E
# P6fhKF1UeT9RNTopHos5muW3ZNO/u4eWz5RhLc78Yq8EV6/p2Zg4Mt8BbG436uXn
# XhYOwmjyhhX1MDUchomMcKa9pRKmGDZjP1RQVK63tVM9oRC7dNErw2rNO/JXCim+
# 0aXo7wkK8B4ZYjzymRY9vOm1z7ZuICSuoM4fKxkTB/0APzD4Yb4CyGPbkvq0MIIF
# WTCCBEGgAwIBAgIQPXjX+XZJYLJhffTwHsqGKjANBgkqhkiG9w0BAQsFADCByjEL
# MAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQLExZW
# ZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTowOAYDVQQLEzEoYykgMjAwNiBWZXJpU2ln
# biwgSW5jLiAtIEZvciBhdXRob3JpemVkIHVzZSBvbmx5MUUwQwYDVQQDEzxWZXJp
# U2lnbiBDbGFzcyAzIFB1YmxpYyBQcmltYXJ5IENlcnRpZmljYXRpb24gQXV0aG9y
# aXR5IC0gRzUwHhcNMTMxMjEwMDAwMDAwWhcNMjMxMjA5MjM1OTU5WjB/MQswCQYD
# VQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNVBAsT
# FlN5bWFudGVjIFRydXN0IE5ldHdvcmsxMDAuBgNVBAMTJ1N5bWFudGVjIENsYXNz
# IDMgU0hBMjU2IENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEP
# ADCCAQoCggEBAJeDHgAWryyx0gjE12iTUWAecfbiR7TbWE0jYmq0v1obUfejDRh3
# aLvYNqsvIVDanvPnXydOC8KXyAlwk6naXA1OpA2RoLTsFM6RclQuzqPbROlSGz9B
# PMpK5KrA6DmrU8wh0MzPf5vmwsxYaoIV7j02zxzFlwckjvF7vjEtPW7ctZlCn0th
# lV8ccO4XfduL5WGJeMdoG68ReBqYrsRVR1PZszLWoQ5GQMWXkorRU6eZW4U1V9Pq
# k2JhIArHMHckEU1ig7a6e2iCMe5lyt/51Y2yNdyMK29qclxghJzyDJRewFZSAEjM
# 0/ilfd4v1xPkOKiE1Ua4E4bCG53qWjjdm9sCAwEAAaOCAYMwggF/MC8GCCsGAQUF
# BwEBBCMwITAfBggrBgEFBQcwAYYTaHR0cDovL3MyLnN5bWNiLmNvbTASBgNVHRMB
# Af8ECDAGAQH/AgEAMGwGA1UdIARlMGMwYQYLYIZIAYb4RQEHFwMwUjAmBggrBgEF
# BQcCARYaaHR0cDovL3d3dy5zeW1hdXRoLmNvbS9jcHMwKAYIKwYBBQUHAgIwHBoa
# aHR0cDovL3d3dy5zeW1hdXRoLmNvbS9ycGEwMAYDVR0fBCkwJzAloCOgIYYfaHR0
# cDovL3MxLnN5bWNiLmNvbS9wY2EzLWc1LmNybDAdBgNVHSUEFjAUBggrBgEFBQcD
# AgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgEGMCkGA1UdEQQiMCCkHjAcMRowGAYD
# VQQDExFTeW1hbnRlY1BLSS0xLTU2NzAdBgNVHQ4EFgQUljtT8Hkzl699g+8uK8zK
# t4YecmYwHwYDVR0jBBgwFoAUf9Nlp8Ld7LvwMAnzQzn6Aq8zMTMwDQYJKoZIhvcN
# AQELBQADggEBABOFGh5pqTf3oL2kr34dYVP+nYxeDKZ1HngXI9397BoDVTn7cZXH
# ZVqnjjDSRFph23Bv2iEFwi5zuknx0ZP+XcnNXgPgiZ4/dB7X9ziLqdbPuzUvM1io
# klbRyE07guZ5hBb8KLCxR/Mdoj7uh9mmf6RWpT+thC4p3ny8qKqjPQQB6rqTog5Q
# IikXTIfkOhFf1qQliZsFay+0yQFMJ3sLrBkFIqBgFT/ayftNTI/7cmd3/SeUx7o1
# DohJ/o39KK9KEr0Ns5cF3kQMFfo2KwPcwVAB8aERXRTl4r0nS1S+K4ReD6bDdAUK
# 75fDiSKxH3fzvc1D1PFMqT+1i4SvZPLQFCExggI1MIICMQIBATCBkzB/MQswCQYD
# VQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNVBAsT
# FlN5bWFudGVjIFRydXN0IE5ldHdvcmsxMDAuBgNVBAMTJ1N5bWFudGVjIENsYXNz
# IDMgU0hBMjU2IENvZGUgU2lnbmluZyBDQQIQXJkusQrBtsaXJ/F/dxsW+DAJBgUr
# DgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkq
# hkiG9w0BCQQxFgQU9h8vdLVDmx2J1C2jOKLmQfPY2jgwDQYJKoZIhvcNAQEBBQAE
# ggEAamQ1V9MaO1EG+gpcj6ZirzY7M4ShuXE71iYeLQYZxO0nrbjbX0erw5Nl3BMv
# 93s8uuetWpp6DlE8dD5AuccAvxGTKRqXprnItE+QZuWmk2knwUT+JgOc2iKKNL4v
# IQ/ng++qGffMndg8nyNHMAE86+6yrfzGMZjJJ7JcCUBTepm1Q447eCcbpezq43S/
# zVvLlkzLQhYty7+BhLYHkVfxQpMAkWkvj1Uwox1qdeeks3t6K2re6KowOBEr/Lzs
# yOz64Re5+99KcD1xoGDD5cyV4Te/EWJeY+f3qmvqO5R2CH9/D1/kV3UQdIhp+omJ
# m6K4DqKeNxEN1ukSnwl0jUz7VQ==
# SIG # End signature block
