
CREATE VIEW VW_OMColunas
AS
SELECT  
      sys.sysobjects.name AS TABELA,
      sys.syscolumns.name AS COLUNA,
      sys.sysobjects.name + '.' + sys.syscolumns.name + ',' AS Coluna2,
         ChavePrimaria.CONSTRAINT_NAME,
    '@' + sys.syscolumns.name + ',' AS Parametro,
    '@' + sys.syscolumns.name + ' ' +
    CASE sys.systypes.name WHEN 'varchar' THEN sys.systypes.name + '(' + CONVERT(VARCHAR, sys.syscolumns.length) + ')'
    WHEN 'char' THEN sys.systypes.name + '(' + CONVERT(VARCHAR, sys.syscolumns.length) + ')'
    ELSE sys.systypes.name
    END + ',' AS ParametroTipo,
    sys.systypes.name AS Tipo,
    sys.syscolumns.length Caracteres,
	sys.syscolumns.colstat AutoIncremento,
    sys.sysobjects.id,
    sys.syscolumns.colorder,
    sys.sysobjects.xtype,
    sys.syscolumns.collation,
    'SELECT*FROM ' + sys.sysobjects.name AS Selecionar,
     
          
CASE sys.sysobjects.xtype WHEN 'U'
THEN
'IF(NOT EXISTS(SELECT 1 FROM SYSOBJECTS INNER JOIN SYSCOLUMNS ON SYSOBJECTS.ID = SYSCOLUMNS.ID AND SYSOBJECTS.XTYPE = ''U'' AND sysobjects.name = ''' + sysobjects.name + ''' AND SYSCOLUMNS.NAME = ''' + SYSCOLUMNS.name + '''))
ALTER TABLE ' + sys.sysobjects.name + ' ADD ' + sys.syscolumns.name + ' ' + sys.systypes.name +
CASE SYSTYPES.name WHEN 'varchar' THEN '(' + CONVERT(VARCHAR, sys.syscolumns.length)+ ')'  WHEN 'char' THEN '(' + CONVERT(VARCHAR, sys.syscolumns.length)+ ')' ELSE '' END END AS CriarColuna

FROM         sys.sysobjects INNER JOIN
                      sys.syscolumns ON sys.sysobjects.id = sys.syscolumns.id INNER JOIN
                      sys.systypes ON sys.systypes.xtype = sys.syscolumns.xtype
LEFT JOIN
(SELECT CONSTRAINT_NAME, COLUMN_NAME, TABLE_NAME,ORDINAL_POSITION  FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE  CONSTRAINT_NAME = (
    SELECT NAME FROM SYSOBJECTS
    WHERE
        INFORMATION_SCHEMA.KEY_COLUMN_USAGE.TABLE_NAME = OBJECT_NAME(SYSOBJECTS.Parent_Obj) AND
        SYSOBJECTS.XTYPE = 'PK'))ChavePrimaria ON SYSOBJECTS.NAME = ChavePrimaria.TABLE_NAME AND syscolumns.name = ChavePrimaria.COLUMN_NAME
WHERE     (sys.sysobjects.xtype = 'U') OR
                      (sys.sysobjects.xtype = 'V')



GO