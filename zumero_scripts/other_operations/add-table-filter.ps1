<#
 .SYNOPSIS
   Add a WHERE filter and optional column exclusions to a synched table.

 .DESCRIPTION
   Adds a simple filter WHERE clause to a TableName, for Any Authenticated User.
   The example filters on a [name] column matching ZUMERO_USER_NAME. Edit the script to use a different WHERE clause.

   The optional -Excludes parameter takes a quoted, comma-separated list of column names to exclude. 

 .PARAMETER DBFile
   The name of the DBFile to which this table belongs.

 .PARAMETER Excludes
   A quoted, comma-separated list of column names to exclude. 

   A column name followed by `=something` will get "something" as a default value for the excluded column; otherwise no default will be set.
 
 .PARAMETER WhereClause
   A quoted WHERE clause used for filtering the rows in the table.
   
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
   .\add-table-filter.ps1 salesdata Invoices -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server
        
   DESCRIPTION
   -----------
   Adds a WHERE filter for Any Authenticated User to the Invoices table in the salesdata DBFile.

 .EXAMPLE
   .\add-table-filter.ps1 salesdata Invoices -PrimaryDBName dbSales -PrimaryServer my.server -SecondaryDBName dbSales -SecondaryServer my.server -Excludes "address,city=Springfield"
        
   DESCRIPTION
   -----------
   Adds a WHERE filter for Any Authenticated User to the Invoices table in the salesdata DBFile. 

   Excludes the "address" column (with no default) and the "city" column (with a default of "Springfield")
   from sync.
   
 #>

 Param(
  [Parameter(Mandatory=$True,Position=1)]
  [string] $DBFile,

  [Parameter(Mandatory=$True,Position=2)]
  [string] $TableName,

  [string] $Excludes,
  [string] $WhereClause,

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
#$whereClause = "'{{{ZUMERO_USER_NAME}}}' = name"

#if ($WhereClause)
#{
#	$whereClause = $WhereClause
#}

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

Function FilterTable($dbfile_name, $table_name)
{
    "Adding filter to " + $table_name

    $authSource = [Zumero.ZumerifyLib.AuthenticationSource]::AuthSourceFromScheme($pdb, $dbfile_name, '{"scheme_type":"table","table":"users"}')
    $u = [Zumero.ZumerifyLib.DB.ZACL]::DB_WHO_ANY_AUTHENTICATED_USER

    $db.Open()

    $table = $db.GetHostTable($table_name)

    $filter = $null

    $filters = $db.GetAllFilters($dbfile_name, $authSource)

    foreach ($flt in $filters)
    {
      if (($flt.Users.Count -eq 1) -and ($flt.Users[0] -eq $u))
      {
        $filter = $flt;
        break;
      }
    }

    if ($filter -eq $null)
    {
      $filter = $db.GetFilter($dbfile_name, $authSource);
    }

    $ft = $filter.Table($table);

    if (! $ft)
    {
      $ft = $db.GetFilteredTable($table);
    }

    $ft.SetWhereClause($WhereClause);

    $hasUser = $false

    if ($filter.Users -ne $null)
    {
      $hasUser = $filter.Users.Contains($u)
    }

    if (! $hasUser)
    {
      $filter.AddUser([Zumero.ZumerifyLib.DB.ZACL]::DB_WHO_ANY_AUTHENTICATED_USER)
    }

    $filter.AddOrUpdateTable($ft);

    if ($Excludes)
    {
      $cols = $table.ExcludableColumns;
      $coldefs = $Excludes.Split(',');

      Foreach($coldef in $coldefs)
      {
        $parts = $coldef.Split('=')

        $col = $parts[0]
        $defval = $null
        if ($parts.Count -gt 1)
        {
          $defval = $parts[1]
        } 

        $query = "column_name = '$col'"
        $matched = $cols.Select($query)
        $count = $matched.Count

        if ($matched.Count -eq 1)
        {
          $colid = $matched[0]['column_id']

          "  excluding [$col]"
    
          if ($defval -eq $null)
          {
            $ft.ExcludeColumn($colid)
          }
          else
          {
            "  default value: $defval"
            $ft.ExcludeColumn($colid, $defval)
          }
        }
        else
        {
          "Column [$col] does not exist in [$table_name], or is not excludable."
          ""
          Exit 1
        }
      }
    }

    $tx = $db.BeginTransaction([System.Data.IsolationLevel]'ReadCommitted');
    $filter.SaveToDB($tx);
    $tx.Commit();

    "close"
    $db.Close()
}

FilterTable $DBFile $TableName

# SIG # Begin signature block
# MIIM/wYJKoZIhvcNAQcCoIIM8DCCDOwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUylXORqK1N5rnELq3tnEJuZdB
# DpWgggo0MIIE0zCCA7ugAwIBAgIQXJkusQrBtsaXJ/F/dxsW+DANBgkqhkiG9w0B
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
# hkiG9w0BCQQxFgQUwhT4luPxDHSY+kWyoZZejhXM5dQwDQYJKoZIhvcNAQEBBQAE
# ggEAWqd5KpBXFc58D05aO102mqyir4dYEGfBz8u20Zh4p+toAAUEJAtLnZ7yuXkg
# cE2Z012Ij+64lqoUaZwbl1GNArpzxe2IV/eqRrRy5eiF2vtjXMGdOUJFc+V0ib81
# 1vtDn6rtu4foseqGKl8qEVckCAq34Ev2mYsd1z0p86IpNMtVpyFFGshx5kghqrTr
# frygfvy517oFQh6OGptx+96INZlnd7o9Q1uG5QUi4zlOcPgwhsOsS/rel2pyN+b1
# B//uHEQhts5H9T3jNH/LUjpxNPSPzkYGEd+VsGldfqaeE8tnrROAbVKjUvbxUHF6
# HAqATZRYyT3lBMbyOU5Anove0g==
# SIG # End signature block
