
IF(EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'SP_OMGERARSCRIPTBASICO'))
	DROP PROC SP_OMGERARSCRIPTBASICO
IF(EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'SP_OMReindexarTabelas'))
	DROP PROC SP_OMReindexarTabelas
IF(EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'VW_OMColunas'))
	DROP VIEW VW_OMColunas
IF(EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'VW_OMRelacionamento'))
	DROP VIEW VW_OMRelacionamento
IF(EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'Vw_ChecarRelacionamento'))
	DROP VIEW Vw_ChecarRelacionamento
IF(EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'SP_ImportarTabela'))
	DROP PROC SP_ImportarTabela
go

CREATE PROC SP_OMGerarScriptBasico
      @TABELA VARCHAR(500)
AS

SET NOCOUNT ON

SET @TABELA = (SELECT NAME FROM SYSOBJECTS WHERE NAME = @TABELA)

SELECT SYSCOLUMNS.NAME INTO #TEMP FROM SYSOBJECTS INNER JOIN SYSCOLUMNS ON SYSOBJECTS.ID = SYSCOLUMNS.ID AND SYSOBJECTS.NAME = @TABELA

DECLARE @COLUNA VARCHAR(200), @SQL VARCHAR(MAX) = ''

WHILE(EXISTS(SELECT 1 FROM #TEMP))
BEGIN
      SET @COLUNA = (SELECT TOP 1 NAME + ', ' FROM #TEMP)
      SET @SQL = @SQL + @COLUNA
      DELETE FROM #TEMP WHERE NAME = REPLACE(@COLUNA, ', ', '')
END

SET NOCOUNT OFF

PRINT '--COLUNAS'
PRINT SUBSTRING(@SQL,0,LEN(@SQL))
PRINT '

--PARAMETROS'
PRINT '@' + REPLACE(SUBSTRING(@SQL,0,LEN(@SQL)), ', ',', @')

PRINT '
--INSERT
INSERT INTO ' + @TABELA + ' (' + SUBSTRING(@SQL,0,LEN(@SQL)) + ')'
PRINT 'VALUES(@' + REPLACE(SUBSTRING(@SQL,0,LEN(@SQL)), ', ',', @') + ')'

DROP TABLE #TEMP

GO

CREATE PROC SP_OMReindexarTabelas
AS
      SELECT 'PRINT ''' + NAME + ''' DBCC DBREINDEX(''' + NAME + ''','''',70)' FROM SYSOBJECTS WHERE XTYPE='U' ORDER BY NAME
GO

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

CREATE VIEW VW_OMRelacionamento
AS
SELECT Q.FK,Q.Coluna,Q.Tabela,Q.Tabela2,'ALTER TABLE ' + Q.Tabela + ' ADD CONSTRAINT ' + Q.FK + ' FOREIGN KEY ( ' + Q.Coluna + ' ) REFERENCES ' + Q.Tabela2 + ' (CODIGO)' SCRIPT FROM
(SELECT  'FK_' + SYSOBJECTS.NAME + '_' + SUBSTRING(SYSCOLUMNS.NAME,7,50)FK,SYSCOLUMNS.NAME Coluna,SYSOBJECTS.NAME Tabela,SUBSTRING(SYSCOLUMNS.NAME,7,50)Tabela2 FROM SYSOBJECTS,SYSCOLUMNS
WHERE SYSOBJECTS.ID = SYSCOLUMNS.ID
AND SYSOBJECTS.XTYPE='U'
AND SYSCOLUMNS.NAME LIKE 'CODIGO%' AND SYSCOLUMNS.NAME <>'CODIGO')Q,SYSOBJECTS
WHERE SYSOBJECTS.NAME = Tabela2 AND SYSOBJECTS.XTYPE='U'
AND FK NOT IN(SELECT NAME FROM SYSOBJECTS WHERE NAME LIKE 'FK%')

GO

CREATE VIEW Vw_ChecarRelacionamento

AS
--esta view foi criada para listar as colunas que possivelmente devam ser relacionadas, mas fogem da padronização de nomes
SELECT syscolumns.name Coluna,sysobjects.name Tabela FROM SYScolumns INNER JOIN SYSOBJECTS ON syscolumns.id = sysobjects.id WHERE SYSCOLUMNS.name LIKE 'Codigo%' and SYSCOLUMNS.name <>'cODIGO'
AND SUBSTRING(SYSCOLUMNS.name,7,20) NOT IN(SELECT SYSOBJECTS.name FROM SYSOBJECTS WHERE XTYPE = 'U')
AND sysobjects.xtype = 'U'

GO

CREATE PROC SP_ImportarTabela
      @BancoOrigem VARCHAR(100),
      @BancoDestino VARCHAR(100),
      @TabelaOrigem VARCHAR(100),
      @TabelaDestino VARCHAR(100)
AS
DECLARE @Coluna varchar(100)
DECLARE @ColunasDestino1 VARCHAR(MAX) = ''
DECLARE @ColunasOrigem1 VARCHAR(MAX) = ''
DECLARE @ColunasDestino2 VARCHAR(MAX) = ''
DECLARE @ColunasOrigem2 VARCHAR(MAX) = ''
DECLARE @Amarracao VARCHAR(MAX) = ''
DECLARE @ValidarNulidade VARCHAR(100) = '1 = 1'
DECLARE @SQL VARCHAR(MAX)
DECLARE @Colorder INT = 0

SELECT COLUNA, CONSTRAINT_NAME,colorder  INTO #TEMP FROM VW_OMColunas WHERE TABELA = @TABELAORIGEM


WHILE(EXISTS(SELECT 1 FROM #TEMP))
BEGIN
	  SET @Colorder = (SELECT MIN(colorder) FROM #TEMP)
      SET @Coluna = (SELECT TOP 1 COLUNA FROM #TEMP WHERE colorder = @Colorder)
      
	  IF(LEN(@ColunasDestino1)<6000)
		SET @ColunasDestino1 = @ColunasDestino1 + @Coluna + ','
	  ELSE
		SET @ColunasDestino2 = @ColunasDestino2 + @Coluna + ','
      IF(LEN(@ColunasOrigem1)<6000)
		SET @ColunasOrigem1 = @ColunasOrigem1 + ' T.' + @Coluna + ','
	  ELSE
		SET @ColunasOrigem2 = @ColunasOrigem2 + ' T.' + @Coluna + ','

     
      IF(EXISTS(SELECT 1 FROM #TEMP WHERE CONSTRAINT_NAME IS NOT NULL AND COLUNA = @Coluna))
      BEGIN
            IF(LEN(@Amarracao)>1)
            SET @Amarracao = @Amarracao + ' AND '
            SET @Amarracao = @Amarracao + 'T.' + @Coluna + ' = T1.' + @Coluna
            SET @ValidarNulidade = @Coluna + ' IS NULL'
      END
     
      DELETE FROM #TEMP where COLUNA = @Coluna
END

IF(LEN(@ColunasDestino2)>0)
	SET @ColunasDestino2 = left(@ColunasDestino2,LEN(@ColunasDestino2)-1) + ')'
ELSE
	SET @ColunasDestino1 = left(@ColunasDestino1,LEN(@ColunasDestino1)-1) + ')'
IF(LEN(@ColunasOrigem2)>0)
	SET @ColunasOrigem2 = left(@ColunasOrigem2,LEN(@ColunasOrigem2)-1)
ELSE
	SET @ColunasOrigem1 = left(@ColunasOrigem1,LEN(@ColunasOrigem1)-1)

IF(LEN(@Amarracao)<1)
BEGIN

PRINT 'PRINT ''Tabela: '+ @TabelaOrigem +'''
IF(NOT EXISTS(SELECT 1 FROM ' + @BancoDestino + '..' + @TabelaOrigem + '))
INSERT INTO ' + @BancoDestino + '..' + @TabelaOrigem + '(' 
PRINT @ColunasDestino1 
IF(LEN(@ColunasDestino2)>0)
PRINT @ColunasDestino2 
PRINT'SELECT ' + @ColunasOrigem1 
IF(LEN(@ColunasOrigem2)>0)
PRINT @ColunasOrigem2 
PRINT 'FROM ' + @BancoOrigem + '..' + @TabelaOrigem + ' T
GO'

END
ELSE
BEGIN
PRINT 'PRINT ''Tabela: '+ @TabelaOrigem +'''
INSERT INTO ' + @BancoDestino + '..' + @TabelaOrigem + '(' 
+ @ColunasDestino1 
IF(LEN(@ColunasDestino2)>0)
PRINT @ColunasDestino2 
PRINT 'SELECT ' + @ColunasOrigem1 
IF(LEN(@ColunasOrigem2)>0)
PRINT @ColunasOrigem2 
PRINT 'FROM ' + @BancoOrigem + '..' + @TabelaOrigem + ' T
LEFT JOIN ' + @BancoDestino + '..' + @TabelaDestino + ' T1 ON ' + @Amarracao + '
WHERE T1.' + @ValidarNulidade + '
GO'
END

PRINT @SQL

DROP TABLE #TEMP

GO
