function Perform-Upgrade($filename, $DBFile, $DoZumero, $AllowAnonymous) {
	$content = [IO.File]::ReadAllText($PSScriptRoot + "\" + $filename + ".sql")
	ExecuteSql-Secondary($content);

	#This format is TABLENAME, SKIPPED_COLUMNS, FILTER
	#It is important that tables in this list are in the proper order
	#FK parents have to come before FK children.
	$tableList = @(
		, @( "ParentTable", 	"SecretCol", "Data like '%filter version 1%'" )
		, @( "ChildTable", 	"", "" )
	)

	if ($DoZumero)
	{
		Create-DBFile $global:primaryDatabase  $global:secondaryDatabase  $DBFile
		Grant-Permissions $global:primaryDatabase $global:secondaryDatabase $DBFile $AllowAnonymous
	
		foreach ($tableObject in $tableList)
		{
			$tName = $tableObject[0];
			$tSkippedColumns = $tableObject[1];
			$tWhereClause = $tableObject[2];
			#"Preparing table " + $tName + " skipping columns " + $tSkippedColumns #+ " Where " + $tWhereClause
			Prepare-And-Filter-Table $global:primaryDatabase $global:secondaryDatabase $DBFile $tName $tWhereClause $tSkippedColumns $AllowAnonymous
		}
	}
}
