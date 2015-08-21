<#

  Utility functions shared by Zumero PowerShell scripts.

 #>

Function getConnString($desc, $server, $db, $user, $pass)
{
  $authString = "Trusted_Connection=true"

  if ($user -and $pass) {
    $authString = "UID=$user;PWD=$pass"
  }
  elseif ($user)
  {
    Write-Host "$desc username was specified with no password"
    Exit 1
  }
  elseif ($pass)
  {
    Write-Host "$desc password was specified with no username"
    Exit 1
  }

  $ConnString = "Server=$server;Database=$db;$authString"

  Return $ConnString
}
