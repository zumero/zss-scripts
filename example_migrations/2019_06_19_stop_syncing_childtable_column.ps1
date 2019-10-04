Function Perform-Upgrade($filename, $DBFile, $DoZumero, $AllowAnonymous) {
	if ($DoZumero)
	{		
		ExecuteSql-Secondary("exec zumero.StopSyncingColumn @schema_name = 'dbo', @table_name = 'ChildTable', @column_name  = 'Data2'");
	}
}
