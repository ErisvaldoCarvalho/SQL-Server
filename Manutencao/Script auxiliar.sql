

PRINT 'Criar objetos para manutenção'

GO

GO
PRINT 'VERIFICAR A DUPLICIDADE DA PROC SP_ImportarTabela'
drop proc SP_ImportarTabela
go
CREATE PROC SP_ImportarTabela
      @BancoOrigem VARCHAR(100),
      @BancoDestino VARCHAR(100),
      @TabelaOrigem VARCHAR(100),
      @TabelaDestino VARCHAR(100)
AS
DECLARE @Coluna varchar(100)
DECLARE @ColunasDestino VARCHAR(MAX) = ''
DECLARE @ColunasOrigem VARCHAR(MAX) = ''
DECLARE @Amarracao VARCHAR(MAX) = ''
DECLARE @ValidarNulidade VARCHAR(100) = '1 = 1'
DECLARE @SQL VARCHAR(MAX)

SELECT COLUNA, CONSTRAINT_NAME  INTO #TEMP FROM VW_OMColunas WHERE TABELA = @TABELAORIGEM


WHILE(EXISTS(SELECT 1 FROM #TEMP))
BEGIN
      SET @Coluna = (SELECT TOP 1 COLUNA FROM #TEMP)
      SET @ColunasDestino = @ColunasDestino + @Coluna + ','
      SET @ColunasOrigem = @ColunasOrigem + ' T.' + @Coluna + ','
     
      IF(EXISTS(SELECT 1 FROM #TEMP WHERE CONSTRAINT_NAME IS NOT NULL AND COLUNA = @Coluna))
      BEGIN
            IF(LEN(@Amarracao)>1)
            SET @Amarracao = @Amarracao + ' AND'
            SET @Amarracao = @Amarracao + 'T.' + @Coluna + ' = T1.' + @Coluna
            SET @ValidarNulidade = @Coluna + ' IS NULL'
      END
     
      DELETE FROM #TEMP where COLUNA = @Coluna
END

SET @ColunasDestino = left(@ColunasDestino,LEN(@ColunasDestino)-1)
SET @ColunasOrigem = left(@ColunasOrigem,LEN(@ColunasOrigem)-1)

SELECT @Amarracao
IF(LEN(@Amarracao)<1)
BEGIN
SET @SQL = '
INSERT INTO ' + @BancoDestino + '..' + @TabelaOrigem + '(' + @ColunasDestino + ')
SELECT ' + @ColunasOrigem + ' FROM ' + @BancoOrigem + '..' + @TabelaOrigem + ' T'

END
ELSE
BEGIN
SET @SQL = '
INSERT INTO ' + @BancoDestino + '..' + @TabelaOrigem + '(' + @ColunasDestino + ')
SELECT ' + @ColunasOrigem + ' FROM ' + @BancoOrigem + '..' + @TabelaOrigem + ' T
LEFT JOIN ' + @BancoDestino + '..' + @TabelaDestino + ' T1 ON ' + @Amarracao + '
WHERE T1.' + @ValidarNulidade
END

PRINT @SQL

DROP TABLE #TEMP


GO


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
PRINT 'Remover objetos criados para manutenção'
GO
DROP PROC SP_OMGERARSCRIPTBASICO
DROP PROC SP_OMReindexarTabelas
DROP VIEW VW_OMColunas
DROP VIEW VW_OMRelacionamento
DROP VIEW Vw_ChecarRelacionamento
DROP PROC SP_ImportarTabela
GO


CREATE PROC SP_ImportarTabela
      @BancoOrigem VARCHAR(100),
      @BancoDestino VARCHAR(100),
      @TabelaOrigem VARCHAR(100),
      @TabelaDestino VARCHAR(100)
AS
DECLARE @Coluna varchar(100)
DECLARE @ColunasDestino VARCHAR(MAX) = ''
DECLARE @ColunasOrigem VARCHAR(MAX) = ''
DECLARE @Amarracao VARCHAR(MAX) = ''
DECLARE @ValidarNulidade VARCHAR(100) = '1 = 1'
DECLARE @SQL VARCHAR(MAX)

SELECT COLUNA, CONSTRAINT_NAME  INTO #TEMP FROM VW_OMColunas WHERE TABELA = @TABELAORIGEM


WHILE(EXISTS(SELECT 1 FROM #TEMP))
BEGIN
      SET @Coluna = (SELECT TOP 1 COLUNA FROM #TEMP)
      SET @ColunasDestino = @ColunasDestino + @Coluna + ','
      SET @ColunasOrigem = @ColunasOrigem + ' T.' + @Coluna + ','
     
      IF(EXISTS(SELECT 1 FROM #TEMP WHERE CONSTRAINT_NAME IS NOT NULL AND COLUNA = @Coluna))
      BEGIN
            IF(LEN(@Amarracao)>1)
            SET @Amarracao = @Amarracao + ' AND'
            SET @Amarracao = @Amarracao + 'T.' + @Coluna + ' = T1.' + @Coluna
            SET @ValidarNulidade = @Coluna + ' IS NULL'
      END
     
      DELETE FROM #TEMP where COLUNA = @Coluna
END

SET @ColunasDestino = left(@ColunasDestino,LEN(@ColunasDestino)-1)
SET @ColunasOrigem = left(@ColunasOrigem,LEN(@ColunasOrigem)-1)

SELECT @Amarracao
IF(LEN(@Amarracao)<1)
BEGIN
SET @SQL = '
INSERT INTO ' + @BancoDestino + '..' + @TabelaOrigem + '(' + @ColunasDestino + ')
SELECT ' + @ColunasOrigem + ' FROM ' + @BancoOrigem + '..' + @TabelaOrigem + ' T'

END
ELSE
BEGIN
SET @SQL = '
INSERT INTO ' + @BancoDestino + '..' + @TabelaOrigem + '(' + @ColunasDestino + ')
SELECT ' + @ColunasOrigem + ' FROM ' + @BancoOrigem + '..' + @TabelaOrigem + ' T
LEFT JOIN ' + @BancoDestino + '..' + @TabelaDestino + ' T1 ON ' + @Amarracao + '
WHERE T1.' + @ValidarNulidade
END

PRINT @SQL

DROP TABLE #TEMP

GO