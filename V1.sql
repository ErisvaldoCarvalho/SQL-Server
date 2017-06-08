



SELECT  
     sys.sysobjects.name AS Tabela,
     sys.syscolumns.name AS Coluna,
     sys.sysobjects.name + '.' + sys.syscolumns.name + ',' AS Coluna2,
    '@' + sys.syscolumns.name + ',' AS Parametro,
    sys.systypes.name AS Tipo,
    sys.syscolumns.length Caracteres,
	sys.syscolumns.colstat AutoIncremento,
    sys.sysobjects.id,
    sys.syscolumns.colorder,
    sys.sysobjects.xtype,
    sys.syscolumns.collation,
    'SELECT*FROM ' + sys.sysobjects.name AS Selecionar
FROM         sys.sysobjects INNER JOIN
                      sys.syscolumns ON sys.sysobjects.id = sys.syscolumns.id INNER JOIN
                      sys.systypes ON sys.systypes.xtype = sys.syscolumns.xtype

WHERE sys.sysobjects.xtype = 'U' 
OR sys.sysobjects.xtype = 'V'

GO