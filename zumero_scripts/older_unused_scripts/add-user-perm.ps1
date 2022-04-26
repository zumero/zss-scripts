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

# SIG # Begin signature block
# MIIM/wYJKoZIhvcNAQcCoIIM8DCCDOwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdqd0LH3PVES5OgobAj+pdzbg
# PSigggo0MIIE0zCCA7ugAwIBAgIQXJkusQrBtsaXJ/F/dxsW+DANBgkqhkiG9w0B
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
# hkiG9w0BCQQxFgQUs92bKpQBSPtBFLSQjKrMAQvrSiswDQYJKoZIhvcNAQEBBQAE
# ggEAQ07C4CVbCgVHjmkSuhh8HMoY22PoaSteAYNiOXP8anqV/obvMc3lsDhwqsC0
# pdo5tOD8AsOFciYZDVt0iS6Pu0wPwKWkFdGQmub1nhPtirktH7M6PFAhCHP73uNz
# gEyQuBfGABgWcMkinkZwnEAMdPHA9j6QpWAbFJkuynbezte7QSTxkiR6U20nC7wV
# Wmtf4B2d3Rb7pI6aD+hM3iaaNFdlfqz/jX+I1k81O8ladHhzdEp7tvHpxco/HQ9Q
# mRDto4lnffjtqwc7lApgft4wuvgl7HOi9SriI4G3oVWLWIuf0eehZfN28DRjpyVd
# zjvnxpfQeYo/KuEvi+n+SwlRDQ==
# SIG # End signature block
