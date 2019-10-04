<#
 .SYNOPSIS
   Delete a DBFile from a ZSS Server configuration.
 
 .DESCRIPTION
   Deletes the DBFile definition and associated scripts. Assumes all tables within the DBFile
   have already been un-prepared (see unprepare-table.ps1).

 .PARAMETER DBFile
   The name of the DBFile being deleted.

 .PARAMETER PrimaryDBName
   The SQL Server database to which your ZSS Server connects, a.k.a the Primary database.

 .PARAMETER PrimaryServer
   The machine name, instance or IP address of the SQL Server hosting the Primary database.

 .PARAMETER PrimaryUsername
   The SQL Server username used when connecting to the Primary database. If omitted, use Trusted Authentication.

 .PARAMETER PrimaryPassword
   The SQL Server password used when connecting to the Primary database. If omitted, use Trusted Authentication.

 .PARAMETER SecondaryDBName
   The SQL Server database containing the DBFile and its tables (on Zumero Servers licensed to sync from multiple databases)

   Defaults to the value of PrimaryDBName

 .PARAMETER SecondaryServer
   The machine name, instance or IP address of the SQL Server hosting containing the DBFile and its tables

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
   .\delete-dbfile.ps1 salesdata -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server
        
   DESCRIPTION
   -----------
   Delete the "salesdata" DBFile from the dbSales database on my.server. Windows Authentication will be used.
   
 .EXAMPLE
   .\delete-dbfile.ps1 salesdata -PrimaryDBName zssconfig -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server -PrimaryUsername sa -PrimaryPassword sapassword
        
   DESCRIPTION
   -----------
   Delete the "salesdata" DBFile from the ZSS Server configuration on my.server::zssconfig, and remove its
   housekeeping data and triggers from my.server::dbSales. Log in as 'sa'.

 #>


Param(
  [Parameter(Mandatory=$True,Position=1)]
  [string] $DBFile,

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
[Reflection.Assembly]::LoadFrom($ZssManagerPath + "\ZssManagerLib.dll") | Out-Null

$ConnString = getConnString "primary" $PrimaryServer $PrimaryDBName $PrimaryUsername $PrimaryPassword
$pdb = [Zumero.ZumerifyLib.DB.ZPrimaryDatabase]::Create(0, $ConnString, $ZssManagerPath + "\DB\SqlServer")

$ConnString = getConnString "secondary" $SecondaryServer $SecondaryDBName $SecondaryUsername $SecondaryPassword
$db =  [Zumero.ZumerifyLib.DB.ZDatabase]::Create(0, $pdb, $ConnString, $ZssManagerPath + "\DB\SqlServer")


Delete-DBFile($DBFile)

# SIG # Begin signature block
# MIIM/wYJKoZIhvcNAQcCoIIM8DCCDOwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUD1ezsaxioht6Qn31ayVXaZti
# gnegggo0MIIE0zCCA7ugAwIBAgIQXJkusQrBtsaXJ/F/dxsW+DANBgkqhkiG9w0B
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
# hkiG9w0BCQQxFgQUXLMlre15HXdHDsrO1cRwgG4nJlkwDQYJKoZIhvcNAQEBBQAE
# ggEAnEeYtjzhuhjWNn2+tcxawadTkVia9x+GhZee3kUnWzagjhHuJBnEkyiVbHIR
# Q7EHOPpdevD7viVwnIiAaI8nbIA0131FASW1SHo50yz2eLbFGCmyNjOjf38PiPvf
# O9cyIBVOQQyGc25OXoZY8mQE6NZu7qMKDJhhfL5AGDcyaychJj5dFPTj99oyFWdy
# sVln/QXvjanVYBoLgw/D/98ZG/lKCcO5CkFP5h9vL22QhrmDda/e74zv1PBzoeF3
# 2czpBSkco3XZgINui5bOrABGHuTAMQvYBk55m0kUBIapQ+CPwZX0fStyu7Zt2YuO
# bQ/0G1D3qFvr83FWN5xA7vKqcA==
# SIG # End signature block
