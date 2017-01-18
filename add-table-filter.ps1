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
  [string] $WhereClause,
  [string] $Excludes,

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

if ([string]::IsNullOrEmpty($WhereClause) -And [string]::IsNullOrEmpty($Excludes))
{
     "This script must provide at least a Where clause or Excludes text"
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
