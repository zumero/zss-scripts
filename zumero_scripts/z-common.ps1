<#

  Utility functions shared by Zumero PowerShell scripts.

 #>

 Function Open-Database($PrimaryServer, $PrimaryDBName, $PrimaryUsername, $PrimaryPassword, $SecondaryServer, $SecondaryDBName, $SecondaryUsername, $SecondaryPassword)
 {
     $ZssManagerPath = [System.IO.Path]::GetFullPath("C:\Program Files (x86)\Zumero\ZSS Manager")
     $env:Path += ";" + $ZssManagerPath + "/x86"
     [Reflection.Assembly]::LoadFrom($ZssManagerPath + "\ZssManagerLib.dll") | Out-Null
 
     $ConnString = getConnString "primary" $PrimaryServer $PrimaryDBName $PrimaryUsername $PrimaryPassword
     $primaryDatabase = [Zumero.ZumerifyLib.DB.ZPrimaryDatabase]::Create(0, $ConnString, $ZssManagerPath + "\DB\SqlServer")
 
     $ConnString = getConnString "secondary" $SecondaryServer $SecondaryDBName $SecondaryUsername $SecondaryPassword
     $secondaryDatabase =  [Zumero.ZumerifyLib.DB.ZDatabase]::Create(0, $primaryDatabase, $ConnString, $ZssManagerPath + "\DB\SqlServer")
 
     $primaryDatabase.Open()
     $secondaryDatabase.Open()
     $primaryDatabase, $secondaryDatabase
 }
 
 Function ExecuteSql-Primary($sql)
 {
     if ($global:UseZSSConnection) {
         $global:primaryDatabase.ExecuteBatchSql($sql)
     }
     else {
         Invoke-Sqlcmd -ConnectionString $global:primarySQLConnectString $sql
     }
 }
 
 Function ExecuteSql-Secondary($sql)
 {
     if ($global:UseZSSConnection) {
         $global:secondaryDatabase.ExecuteBatchSql($sql)
     }
     else {
         Invoke-Sqlcmd -ConnectionString $global:secondarySQLConnectString $sql
     }
 }
 
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
 
 if (! $PSScriptRoot) {
   $PSScriptRoot = split-path -parent $MyInvocation.MyCommand.Definition
 } 
 
 Function Create-DBFile($pdb, $db, $dbfile_name, $PrimaryServer="", $PrimaryUsername="", $PrimaryPassword="", $SecondaryServer="", $SecondaryUsername="", $SecondaryPassword="")
 {
     if (!$pdb.DbFileExists($db, $dbfile_name))
     {
         $scheme = '{"scheme_type":"table","table":"users"}';
 
         if ($pdb.SameDatabase($db))
         {
           $pdb.SaveDBFile($dbfile_name, $null, $null, $null, $scheme);
         }
         elseif (($SecondaryServer -eq $PrimaryServer) -and ($SecondaryUsername -eq $PrimaryUsername) -and ($SecondaryPassword -eq $PrimaryPassword))
         {
           $pdb.SaveDBFile($dbfile_name, $db.DataSource, $db.Database, "zssdb:$SecondaryDBName", $scheme);
         }
         else
         {
           $pdb.SaveDBFile($dbfile_name, $db.DataSource, $db.Database, "Driver={SQL Server Native Client 11.0};$ConnString", $scheme);
         }
 
         "Creating DBFile " + $dbfile_name
         $script = $db.GetCreateDbFileSqlScript($dbfile_name)
         $db.ExecuteBatchSql($script)
     }
     else
     {
         "DBFile " + $dbfile_name + " already exists"
     }
 
     if (! $db.UserTableExists())
     {
         "creating zumero.users table"
         $db.CreateUserTable();
     }
 }
 
 
 Function Delete-DBFile($pdb, $db, $dbfile_name)
 {
    if ($pdb.DbFileExists($db, $dbfile_name))
     {
         "Deleting DBFile " + $dbfile_name
         $script = $db.GetDeleteDbFileSqlScript($dbfile_name)
 
 #        "$script"
 
         $db.ExecuteBatchSql($script)
 
         $pdb.DeleteDBFile($dbfile_name);
     }
     else
     {
         "DBFile " + $dbfile_name + " does not exist in this primary database."
     }
 
     $db.Close();
     $pdb.Close()
 }
 
 Function Prepare-And-Filter-Table($primaryDatabase, $secondaryDatabase, $DBFile, $tName, $tWhereClause, $tSkippedColumns, $anyone = $false)
 {
     Prepare-Table $secondaryDatabase $DBFile $tName $tSkippedColumns
     if ($tWhereClause -or $tSkippedColumns)
     {
 		#"Filtering table " + $tName + " Where " + $tWhereClause + " Skipping " + $tSkippedColumns
         FilterTable $primaryDatabase $secondaryDatabase $DBFile $tName $tWhereClause $tSkippedColumns $anyone
     }
 }
 
 Function Prepare-Table($db, $dbfile_name, $table_name, $skipped_columns = "")
 {
     "Preparing " + $table_name + " in dbfile " + $dbfile_name
     # instantiate table to prepare
     $table = $db.GetHostTable($table_name)
     if (!$table.Prepared)
     {
         $whyNot = New-Object 'System.Collections.Generic.List[string]'
         ###if ($table.CanBePrepared($dbfile_name, [ref]$whyNot))
         ###{
             # print warnings, if there are any
             if ($table.IncompatibilityWarnings -ne $null)
             {
                 foreach ($warning in $table.IncompatibilityWarnings)
                 {
         #            "  Warning: " + $warning
                 }
             }
 
             # Set the skipped columns
             $skipColumns = $skipped_columns.Split(',');
             foreach ($skipColumn in $skipColumns)
             {
             	 $coldef = $skipColumn.Split('=');
                 if ($coldef.Count -gt 1)
		 {
                   "while preparing, skipped column " + $coldef[0] + " has a default, so it will have to be skipped using a filter"
		 }
		 else
                 {
                   $table.SkippedColumns.Add($coldef[0]);
		 }
             }
             # prepare
             $prepare_script = $table.GetPrepareSqlScript($dbfile_name)
             [Action]$action = {param() 
                 $db.ExecuteBatchSql($prepare_script)
                 }
             $outmessages = $null
             if (!$db.ExecuteDBOperationAndCaptureMessages($action, [ref]$outmessages))
             {
                 foreach ($warning in $outmessages)
                 {
                     "  SQL Server Message: " + $warning
                 }
                 throw "Unable to prepare table " + $table_name
             }
             
             #if ($outmessages)
             #{
                 foreach ($warning in $outmessages)
                 {
                     "  SQL Server Message: " + $warning
                 }
             #}
         ###}
         ###else
         ###{
             ###throw "Unable to prepare table " + $table_name + ": " + [System.String]::Join("; ", $whyNot.ToArray())
         ###}
     }
     else
     {
         "Table " + $table_name + " is already prepared."
     }
 }
 
 Function Unprepare-Table($db, $dbfile_name, $table_name)
 {
     "Un-preparing " + $table_name + " in dbfile " + $dbfile_name
 
     if ($db.TableExists($table_name))
     {
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
     }
     else
     {
         $table_name + " doesn't exist."
     }
 }
 
 
 Function Grant-Permissions($pdb, $db, $dbfile_name, $anyone)
 {
     # Give permissions to any authenticated user.
     if ($anyone -eq $true)
     {
       $u = [Zumero.ZumerifyLib.DB.ZACL]::UI_WHO_ANYONE
       $gpermission = $db.GetGroupPermissions($dbfile_name, $u)
     }
     else
     {
       $u = [Zumero.ZumerifyLib.DB.ZACL]::UI_WHO_ANY_AUTHENTICATED_USER
       $authSource = [Zumero.ZumerifyLib.AuthenticationSource]::AuthSourceFromScheme($pdb, $dbfile_name, '{"scheme_type":"table","table":"users"}')
       $gpermission = $db.GetGroupPermissions($authSource, $u)
     }
     "Granting permissions for " + $u
     $gpermission.Table = $null
     $gpermission.ExplicitPull = "Allow"
     $gpermission.ExplicitAdd = "Allow"
     $gpermission.ExplicitMod = "Allow"
     $gpermission.ExplicitDel = "Allow"
     $gpermission.CommitToDB($u, [Zumero.ZumerifyLib.DB.ZPermissions]::DEFAULT_UNCHANGED_PASS)
 }
 
 Function FilterTable($pdb, $db, $dbfile_name, $table_name, $WhereClause, $Excludes, $anyone)
 {
     "Adding filter to " + $table_name
 
     #$authSource = [Zumero.ZumerifyLib.AuthenticationSource]::AuthSourceFromScheme($pdb, $dbfile_name, '{"scheme_type":"table","table":"users"}')
     $authSource = [Zumero.ZumerifyLib.DatabaseAuthSource]::new($dbfile_name, $db, $dbfile_name, 'users')
     if ($anyone -eq $true)
     {
       $u = [Zumero.ZumerifyLib.DB.ZACL]::DB_WHO_ANYONE
     }
     else
     {
       $u = [Zumero.ZumerifyLib.DB.ZACL]::DB_WHO_ANY_AUTHENTICATED_USER
     }
 
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
       $filter.AddUser($u)
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
 }
 
 Function Resolve-Error
 {
 <#
 .SYNOPSIS
     Enumerate error record details.
 
 .DESCRIPTION
     Enumerate an error record, or a collection of error record, properties. By default, the details
     for the last error will be enumerated.
 
 .PARAMETER ErrorRecord
     The error record to resolve. The default error record is the lastest one: $global:Error[0].
     This parameter will also accept an array of error records.
 
 .PARAMETER Property
     The list of properties to display from the error record. Use "*" to display all properties.
     Default list of error properties is: Message, FullyQualifiedErrorId, ScriptStackTrace, PositionMessage, InnerException
 
     Below is a list of all of the possible available properties on the error record:
 
     Error Record:               Error Invocation:           Error Exception:                    Error Inner Exception(s):
     $_                          $_.InvocationInfo           $_.Exception                        $_.Exception.InnerException
     -------------               -----------------           ----------------                    ---------------------------
     writeErrorStream            MyCommand                   ErrorRecord                         Data
     PSMessageDetails            BoundParameters             ItemName                            HelpLink
     Exception                   UnboundArguments            SessionStateCategory                HResult
     TargetObject                ScriptLineNumber            StackTrace                          InnerException
     CategoryInfo                OffsetInLine                WasThrownFromThrowStatement         Message
     FullyQualifiedErrorId       HistoryId                   Message                             Source
     ErrorDetails                ScriptName                  Data                                StackTrace
     InvocationInfo              Line                        InnerException                      TargetSite
     ScriptStackTrace            PositionMessage             TargetSite                          
     PipelineIterationInfo       PSScriptRoot                HelpLink                            
                                 PSCommandPath               Source                              
                                 InvocationName              HResult                             
                                 PipelineLength              
                                 PipelinePosition            
                                 ExpectingInput              
                                 CommandOrigin               
                                 DisplayScriptPosition       
 
 .PARAMETER GetErrorRecord
     Get error record details as represented by $_
     Default is to display details. To skip details, specify -GetErrorRecord:$false
 
 .PARAMETER GetErrorInvocation
     Get error record invocation information as represented by $_.InvocationInfo
     Default is to display details. To skip details, specify -GetErrorInvocation:$false
 
 .PARAMETER GetErrorException
     Get error record exception details as represented by $_.Exception
     Default is to display details. To skip details, specify -GetErrorException:$false
 
 .PARAMETER GetErrorInnerException
     Get error record inner exception details as represented by $_.Exception.InnerException.
     Will retrieve all inner exceptions if there is more then one.
     Default is to display details. To skip details, specify -GetErrorInnerException:$false
 
 .EXAMPLE
     Resolve-Error
 
     Get the default error details for the last error
 
 .EXAMPLE
     Resolve-Error -ErrorRecord $global:Error[0,1]
 
     Get the default error details for the last two errors
 
 .EXAMPLE
     Resolve-Error -Property *
 
     Get all of the error details for the last error
 
 .EXAMPLE
     Resolve-Error -Property InnerException
 
     Get the "InnerException" for the last error
 
 .EXAMPLE
     Resolve-Error -GetErrorInvocation:$false
 
     Get the default error details for the last error but exclude the error invocation information
 
 .NOTES
 .LINK
 #>
     [CmdletBinding()]
     Param
     (
         [Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
         [ValidateNotNullorEmpty()]
         [array]$ErrorRecord,
 
         [Parameter(Mandatory=$false, Position=1)]
         [ValidateNotNullorEmpty()]
         [string[]]$Property = ('Message','InnerException','FullyQualifiedErrorId','ScriptStackTrace','PositionMessage'),
 
         [Parameter(Mandatory=$false, Position=2)]
         [switch]$GetErrorRecord = $true,
 
         [Parameter(Mandatory=$false, Position=3)]
         [switch]$GetErrorInvocation = $true,
 
         [Parameter(Mandatory=$false, Position=4)]
         [switch]$GetErrorException = $true,
 
         [Parameter(Mandatory=$false, Position=5)]
         [switch]$GetErrorInnerException = $true
     )
 
     Begin
     {
         ## If function was called without specifying an error record, then choose the latest error that occured
         If (-not $ErrorRecord)
         {
             If ($global:Error.Count -eq 0)
             {
                 # The `$Error collection is empty
                 Return
             }
             Else
             {
                 [array]$ErrorRecord = $global:Error[0]
             }
         }
 
         ## Define script block for selecting and filtering the properties on the error object
         [scriptblock]$SelectProperty = {
             Param
             (
                 [Parameter(Mandatory=$true)]
                 [ValidateNotNullorEmpty()]
                 $InputObject,
 
                 [Parameter(Mandatory=$true)]
                 [ValidateNotNullorEmpty()]
                 [string[]]$Property
             )
             [string[]]$ObjectProperty = $InputObject | Get-Member -MemberType *Property | Select-Object -ExpandProperty Name
             ForEach ($Prop in $Property)
             {
                 If ($Prop -eq '*')
                 {
                     [string[]]$PropertySelection = $ObjectProperty
                     Break
                 }
                 ElseIf ($ObjectProperty -contains $Prop)
                 {
                     [string[]]$PropertySelection += $Prop
                 }
             }
             Write-Output $PropertySelection
         }
 
         # Initialize variables to avoid error if 'Set-StrictMode' is set
         $LogErrorRecordMsg      = $null
         $LogErrorInvocationMsg  = $null
         $LogErrorExceptionMsg   = $null
         $LogErrorMessageTmp     = $null
         $LogInnerMessage        = $null
     }
     Process
     {
         ForEach ($ErrRecord in $ErrorRecord)
         {
             ## Capture Error Record
             If ($GetErrorRecord)
             {
                 [string[]]$SelectedProperties = &$SelectProperty -InputObject $ErrRecord -Property $Property
                 $LogErrorRecordMsg = $ErrRecord | Select-Object -Property $SelectedProperties
             }
 
             ## Error Invocation Information
             If ($GetErrorInvocation)
             {
                 If ($ErrRecord.InvocationInfo)
                 {
                     [string[]]$SelectedProperties = &$SelectProperty -InputObject $ErrRecord.InvocationInfo -Property $Property
                     $LogErrorInvocationMsg = $ErrRecord.InvocationInfo | Select-Object -Property $SelectedProperties
                 }
             }
 
             ## Capture Error Exception
             If ($GetErrorException)
             {
                 If ($ErrRecord.Exception)
                 {
                     [string[]]$SelectedProperties = &$SelectProperty -InputObject $ErrRecord.Exception -Property $Property
                     $LogErrorExceptionMsg = $ErrRecord.Exception | Select-Object -Property $SelectedProperties
                 }
             }
 
             ## Display properties in the correct order
             If ($Property -eq '*')
             {
                 # If all properties were chosen for display, then arrange them in the order
                 #  the error object displays them by default.
                 If ($LogErrorRecordMsg)     {[array]$LogErrorMessageTmp += $LogErrorRecordMsg    }
                 If ($LogErrorInvocationMsg) {[array]$LogErrorMessageTmp += $LogErrorInvocationMsg}
                 If ($LogErrorExceptionMsg)  {[array]$LogErrorMessageTmp += $LogErrorExceptionMsg }
             }
             Else
             {
                 # Display selected properties in our custom order
                 If ($LogErrorExceptionMsg)  {[array]$LogErrorMessageTmp += $LogErrorExceptionMsg }
                 If ($LogErrorRecordMsg)     {[array]$LogErrorMessageTmp += $LogErrorRecordMsg    }
                 If ($LogErrorInvocationMsg) {[array]$LogErrorMessageTmp += $LogErrorInvocationMsg}
             }
 
             If ($LogErrorMessageTmp)
             {
                 $LogErrorMessage  = 'Error Record:'
                 $LogErrorMessage += "`n-------------"
                 $LogErrorMsg      = $LogErrorMessageTmp | Format-List | Out-String
                 $LogErrorMessage += $LogErrorMsg
             }
 
             ## Capture Error Inner Exception(s)
             If ($GetErrorInnerException)
             {
                 If ($ErrRecord.Exception -and $ErrRecord.Exception.InnerException)
                 {
                     $LogInnerMessage  = 'Error Inner Exception(s):'
                     $LogInnerMessage += "`n-------------------------"
 
                     $ErrorInnerException = $ErrRecord.Exception.InnerException
                     $Count = 0
 
                     While ($ErrorInnerException)
                     {
                         $InnerExceptionSeperator = '~' * 40
 
                         [string[]]$SelectedProperties = &$SelectProperty -InputObject $ErrorInnerException -Property $Property
                         $LogErrorInnerExceptionMsg = $ErrorInnerException | Select-Object -Property $SelectedProperties | Format-List | Out-String
 
                         If ($Count -gt 0)
                         {
                             $LogInnerMessage += $InnerExceptionSeperator
                         }
                         $LogInnerMessage += $LogErrorInnerExceptionMsg
 
                         $Count++
                         $ErrorInnerException = $ErrorInnerException.InnerException
                     }
                 }
             }
 
             If ($LogErrorMessage) { $Output += $LogErrorMessage }
             If ($LogInnerMessage) { $Output += $LogInnerMessage }
 
             Write-Output $Output
 
             If (Test-Path -Path 'variable:Output'            ) { Clear-Variable -Name Output             }
             If (Test-Path -Path 'variable:LogErrorMessage'   ) { Clear-Variable -Name LogErrorMessage    }
             If (Test-Path -Path 'variable:LogInnerMessage'   ) { Clear-Variable -Name LogInnerMessage    }
             If (Test-Path -Path 'variable:LogErrorMessageTmp') { Clear-Variable -Name LogErrorMessageTmp }
         }
     }
     End {}
 }
