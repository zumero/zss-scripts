function Perform-Upgrade($filename, $DBFile, $DoZumero, $AllowAnonymous) {
	
	if ($DoZumero)
	{
		FilterTable $global:primaryDatabase $global:secondaryDatabase $DBFile "ParentTable" "Data like '%filter version 2%'" $null $AllowAnonymous
	}
}
