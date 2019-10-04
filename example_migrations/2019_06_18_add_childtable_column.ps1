Function Perform-Upgrade($filename, $DBFile, $DoZumero, $AllowAnonymous) {
	ExecuteSql-Secondary("ALTER TABLE ChildTable ADD Data2 nvarchar(max);");

	if ($DoZumero)
	{		
		ExecuteSql-Secondary("exec zumero.StartSyncingColumn @schema_name = 'dbo', @table_name = 'ChildTable', @column_name  = 'Data2'");
	}
}
