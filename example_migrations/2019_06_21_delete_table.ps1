Function Perform-Upgrade($filename, $DBFile, $DoZumero, $AllowAnonymous) {
	if ($DoZumero -eq $true)
	{
		Unprepare-Table $global:secondaryDatabase $DBFile "UnneededTable"
	}
	ExecuteSql-Secondary("DROP TABLE UnneededTable;");
}
