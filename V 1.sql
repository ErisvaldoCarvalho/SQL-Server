
CREATE VIEW VW_OM
SELECT  
    sys.sysobjects.name AS Tabela,
    sys.syscolumns.name AS Coluna,
    sys.systypes.name AS Tipo,
    sys.syscolumns.length Caracteres,
    sys.sysobjects.id,
    sys.syscolumns.colorder,
    sys.sysobjects.xtype
FROM sys.sysobjects 
	INNER JOIN sys.syscolumns ON sys.sysobjects.id = sys.syscolumns.id 
	INNER JOIN sys.systypes ON sys.systypes.xtype = sys.syscolumns.xtype
WHERE sys.sysobjects.xtype = 'U' OR sys.sysobjects.xtype = 'V'
GO