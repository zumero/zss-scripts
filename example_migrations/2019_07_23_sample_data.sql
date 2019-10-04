BEGIN TRANSACTION
SET NOCOUNT ON
begin try

INSERT [dbo].[ParentTable] ([Id], [Data], [SecretCol]) VALUES (N'972b281f-190b-abc0-d624-2beb85aea925', N'Sample Data 1', 'secret')
INSERT [dbo].[ParentTable] ([Id], [Data], [SecretCol]) VALUES (N'4159b63d-af50-dbb7-ebff-655d03e6e572', N'Sample Data 2', 'secret')
INSERT [dbo].[ParentTable] ([Id], [Data], [SecretCol]) VALUES (N'8222f1b9-3225-1820-328f-ba6ed59b2d5c', N'Sample Data 3', 'secret')
INSERT [dbo].[ChildTable] ([Id], [ParentId], [Data]) VALUES (N'c9911fe8-eafe-48b7-960b-1e906b975a02', N'972b281f-190b-abc0-d624-2beb85aea925', N'Sample Child Data 1', 'secret')
INSERT [dbo].[ChildTable] ([Id], [ParentId], [Data]) VALUES (N'fa56562f-1e95-483b-bc6b-5fb5ad049a16', N'4159b63d-af50-dbb7-ebff-655d03e6e572', N'Sample Child Data 2', 'secret')
INSERT [dbo].[ChildTable] ([Id], [ParentId], [Data]) VALUES (N'96f74a8c-4449-4ec3-9404-56c4584906ed', N'8222f1b9-3225-1820-328f-ba6ed59b2d5c', N'Sample Child Data 3', 'secret')

COMMIT
end try
begin catch
ROLLBACK;
THROW;
end catch;
