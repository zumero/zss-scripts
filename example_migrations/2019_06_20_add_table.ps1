function Perform-Upgrade($filename, $DBFile, $DoZumero, $AllowAnonymous) {
	$content = [IO.File]::ReadAllText($PSScriptRoot + "\" + $filename + ".sql")
	ExecuteSql-Secondary($content);



	$tableList = @(
		, @( "UnneededTable", 	"", "" )
	)

	if ($DoZumero)
	{			
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
