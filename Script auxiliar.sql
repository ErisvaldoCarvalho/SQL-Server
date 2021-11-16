/*
O repositório foi clonado para o meu Notebook dia 16/11/2021
*/
/*
RODANDO ESTE SCRIPT SERÃO CRIADOS EM TODOS OS BANCOS 
DE DADOS ATACHADOS NO SERVIDOR OS COMPONENTES QUE 
AUXLIAM NA MANUTENÇÃO DE BANCO DE DADOS.
*/

USE master
GO
/*
IF NOT EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'Bancos')
	select name into Bancos from sys.databases
GO

DECLARE @SQL VARCHAR(MAX)

WHILE(EXISTS(SELECT 1 FROM Bancos))
BEGIN
	SET @SQL = (SELECT TOP 1 'USE ' + name FROM Bancos)
	EXEC (@SQL)
	print @sql
	SET @SQL = (SELECT TOP 1 'DELETE FROM MASTER..Bancos WHERE Name = ''' + name +'''' FROM Bancos)
	EXEC (@SQL)
	print @sql
END

IF EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'Bancos')
	IF NOT EXISTS(SELECT 1 FROM Bancos)
		DROP TABLE Bancos
go
*/
IF(EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'Fn_Hexadecimal'))
	DROP FUNCTION Fn_Hexadecimal
IF(EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'SP_MostrarBloqueios'))
	DROP PROC SP_MostrarBloqueios
IF(EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'Fn_PrimeirasMaiusculas'))
	DROP FUNCTION Fn_PrimeirasMaiusculas
IF(EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'SP_OMGerarScriptBasico'))
	DROP PROC SP_OMGerarScriptBasico
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
IF(EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'SP_OrganizarSequencia'))	
	DROP PROC SP_OrganizarSequencia
IF(EXISTS(SELECT 1 FROM SYS.OBJECTS WHERE NAME LIKE 'Vw_OMTabelas'))
	DROP VIEW Vw_OMTabelas	
IF(EXISTS(SELECT 1 FROM SYS.OBJECTS WHERE NAME LIKE 'SP_TabelasFaltantes'))
	DROP PROC SP_TabelasFaltantes
IF(EXISTS(SELECT 1 FROM SYS.OBJECTS WHERE NAME LIKE 'SP_InserirColuna'))
	DROP PROC SP_InserirColuna
IF(EXISTS(SELECT 1 FROM SYS.OBJECTS WHERE NAME LIKE 'SP_InserirColunasIniciais'))
	DROP PROC SP_InserirColunasIniciais
IF(EXISTS(SELECT 1 FROM SYS.OBJECTS WHERE NAME LIKE 'SP_RemoverColunasFinais'))
	DROP PROC SP_RemoverColunasFinais
IF(EXISTS(SELECT 1 FROM SYS.OBJECTS WHERE NAME LIKE 'SP_InserirColunasFinais'))
	DROP PROC SP_InserirColunasFinais
IF(EXISTS(SELECT 1 FROM SYS.OBJECTS WHERE NAME LIKE 'SP_MostrarEstrutura'))
	DROP PROC SP_MostrarEstrutura
	
GO	

CREATE FUNCTION [dbo].[Fn_Hexadecimal](
    @Numero INT
)
RETURNS VARCHAR(50)
AS
BEGIN
     DECLARE 
        @Sequencia VARCHAR(16) = '0123456789ABCDEF',
        @Resultado VARCHAR(50),
        @Digito CHAR(1)   
    
    SET @Resultado = SUBSTRING(@Sequencia, (@Numero % 16) + 1, 1)
 
    WHILE (@Numero > 0)
    BEGIN    
        SET @Digito = SUBSTRING(@Sequencia, ((@Numero / 16) % 16) + 1, 1)
        SET @Numero = @Numero / 16

        IF (@Numero != 0 )
            SET @Resultado = @Digito + @Resultado            
    END 
 
    RETURN @Resultado    
END
GO

CREATE PROC SP_MostrarBloqueios
AS
	SET NOCOUNT ON

	CREATE TABLE #Temp
	(
		Eventtype NVARCHAR(30)NOT NULL,
		Parameters INT NOT NULL,
		EventInfo NVARCHAR(255)NOT NULL
	)
	
	CREATE TABLE #Comandos
	(
		Descricao VARCHAR(100),
		Spid INT,
		Eventtype NVARCHAR(30)NOT NULL,
		Parameters INT NOT NULL,
		EventInfo NVARCHAR(255)NOT NULL
	)

	DECLARE @Blocked INT, @Spid INT, @Comando VARCHAR(255),
	@Conexao INT

	SELECT * INTO #SYSPROCESSESTEMP	FROM MASTER.DBO.SYSPROCESSES WHERE BLOCKED > 0

    SET ROWCOUNT 1
    WHILE EXISTS(SELECT 1 FROM #SYSPROCESSESTEMP)
    BEGIN
		SELECT @Blocked = blocked, @Spid = spid FROM #SYSPROCESSESTEMP

		SET @Conexao = @Blocked -- Conexao
		SET @Comando = 'DBCC INPUTBUFFER(' + CONVERT(VARCHAR, @Conexao) + ')'

		INSERT INTO #Temp
		EXEC (@Comando)

		INSERT INTO #Comandos(Descricao, spid, Eventtype, Parameters, EventInfo) (SELECT 'Bloqueando o ' + CONVERT(VARCHAR, @spid), @Conexao, Eventtype, Parameters, EventInfo FROM #Temp)

		SET @Conexao = @Spid -- Conexao
		SET @Comando = 'DBCC INPUTBUFFER(' + Convert(VarChar, @Conexao) + ')'

		DELETE FROM #Temp

		INSERT INTO #Temp
		EXEC (@Comando)

		INSERT INTO #Comandos(Descricao, Spid, Eventtype, Parameters, EventInfo) (SELECT 'Bloqueado pelo ' + CONVERT(VARCHAR, @blocked), @Conexao, Eventtype, Parameters, EventInfo FROM #Temp)
		
		DELETE FROM #SYSPROCESSESTEMP WHERE spid = @Spid AND blocked = @Blocked
	END
	SET ROWCOUNT 0
	SELECT*FROM #Comandos
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
      @TabelaDestino VARCHAR(100) = NULL
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

IF(@TabelaDestino IS NULL)
	SET @TabelaDestino = @TabelaOrigem

SET NOCOUNT ON

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

PRINT 'PRINT ''Tabela: '+ @TabelaOrigem +''''
IF(EXISTS(SELECT 1 FROM VW_OMColunas WHERE TABELA = @TabelaOrigem AND AutoIncremento > 0))
PRINT 'SET IDENTITY_INSERT ' + @BancoDestino + '..' + @TabelaOrigem + ' ON'
PRINT'IF(NOT EXISTS(SELECT 1 FROM ' + @BancoDestino + '..' + @TabelaOrigem + '))
INSERT INTO ' + @BancoDestino + '..' + @TabelaOrigem + '(' 
PRINT @ColunasDestino1 
IF(LEN(@ColunasDestino2)>0)
PRINT @ColunasDestino2 
PRINT'SELECT ' + @ColunasOrigem1 
IF(LEN(@ColunasOrigem2)>0)
PRINT @ColunasOrigem2 
PRINT 'FROM ' + @BancoOrigem + '..' + @TabelaOrigem + ' T'
IF(EXISTS(SELECT 1 FROM VW_OMColunas WHERE TABELA = @TabelaOrigem AND AutoIncremento > 0))
PRINT 'SET IDENTITY_INSERT ' + @BancoDestino + '..' + @TabelaOrigem + ' OFF'
PRINT'GO'

END
ELSE
BEGIN
PRINT 'PRINT ''Tabela: '+ @TabelaOrigem +''''
IF(EXISTS(SELECT 1 FROM VW_OMColunas WHERE TABELA = @TabelaOrigem AND AutoIncremento > 0))
PRINT'SET IDENTITY_INSERT ' + @BancoDestino + '..' + @TabelaOrigem + ' ON'
PRINT'INSERT INTO ' + @BancoDestino + '..' + @TabelaOrigem + '(' 
+ @ColunasDestino1 
IF(LEN(@ColunasDestino2)>0)
PRINT @ColunasDestino2 
PRINT 'SELECT ' + @ColunasOrigem1 
IF(LEN(@ColunasOrigem2)>0)
PRINT @ColunasOrigem2 
PRINT 'FROM ' + @BancoOrigem + '..' + @TabelaOrigem + ' T
LEFT JOIN ' + @BancoDestino + '..' + @TabelaDestino + ' T1 ON ' + @Amarracao + '
WHERE T1.' + @ValidarNulidade 
IF(EXISTS(SELECT 1 FROM VW_OMColunas WHERE TABELA = @TabelaOrigem AND AutoIncremento > 0))
PRINT 'SET IDENTITY_INSERT ' + @BancoDestino + '..' + @TabelaOrigem + ' OFF'
PRINT'GO'
END

PRINT @SQL

DROP TABLE #TEMP
SET NOCOUNT OFF
GO

GO
CREATE PROC SP_OrganizarSequencia
	@Tabela VARCHAR(200),
	@ColunaAConcatenar VARCHAR(200) = 'CodLoja',
	@ColunaChave VARCHAR(200) = 'Codigo',
	@ColunaSequencia VARCHAR(200) = 'Sequencia'
AS

DECLARE @SQL VARCHAR(MAX) =

'DECLARE @Concatenar FLOAT
IF(NOT EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''' + @Tabela + ''' AND COLUNA = ''NovaSequencia''))
	ALTER TABLE ' + @Tabela + ' ADD NovaSequencia FLOAT
IF(NOT EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''' + @Tabela + ''' AND COLUNA = ''NovoCodigo''))
	ALTER TABLE ' + @Tabela + ' ADD NovoCodigo FLOAT
ELSE
	UPDATE ' + @Tabela + ' SET NovoCodigo = NULL
WHILE(EXISTS(SELECT 1 FROM ' + @Tabela + ' WHERE NovoCodigo IS NULL))
BEGIN
	SET @Concatenar =  (SELECT MIN(' + @ColunaAConcatenar + ') FROM ' + @Tabela + ' WHERE NovoCodigo IS NULL AND ' + @ColunaAConcatenar + ' IS NOT NULL)
	IF(EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''OrganizarSequencia''))
	DROP TABLE OrganizarSequencia
	CREATE TABLE OrganizarSequencia
	(
		Sequencia INT PRIMARY KEY IDENTITY(1,1),
		ChaveOrigem FLOAT,
		Concatenar FLOAT
	)
	INSERT INTO OrganizarSequencia(ChaveOrigem, Concatenar)
	SELECT ' + @ColunaChave + ', ' + @ColunaAConcatenar + ' FROM ' + @Tabela + ' WHERE ' + @ColunaAConcatenar + ' = @Concatenar
	UPDATE ' + @Tabela + '
	SET NovoCodigo = CONVERT(FLOAT, CONVERT(VARCHAR, OrganizarSequencia.Concatenar) + CONVERT(VARCHAR, OrganizarSequencia.Sequencia)), NovaSequencia = OrganizarSequencia.Sequencia
	FROM ' + @Tabela + '
	INNER JOIN OrganizarSequencia ON OrganizarSequencia.ChaveOrigem = ' + @Tabela + '.' + @ColunaChave + '
END'

PRINT @SQL

EXEC (@SQL)
GO


CREATE VIEW Vw_OMTabelas
AS
/*
	View para listar a quantidade de registros e espaço ocupado em disco pelas tabelas.
	Data de criação: 09/08/2018
	Ultima atualização: 09/08/2018
*/
SELECT
    SYS.TABLES.NAME AS Entidade,
    SYS.PARTITIONS.rows AS Registros,
	
	(SUM(SYS.ALLOCATION_UNITS.total_pages) * 8) / 1024.0 / 1024.0 AS EspacoTotalGB,
    (SUM(SYS.ALLOCATION_UNITS.used_pages) * 8) / 1024.0 / 1024.0 AS EspacoUsadoGB,
    ((SUM(SYS.ALLOCATION_UNITS.total_pages) - SUM(SYS.ALLOCATION_UNITS.used_pages)) * 8) / 1024.0 / 1024.0 AS EspacoNaoUsadoGB,

	(SUM(SYS.ALLOCATION_UNITS.total_pages) * 8) / 1024.0 AS EspacoTotalMB,
    (SUM(SYS.ALLOCATION_UNITS.used_pages) * 8) / 1024.0 AS EspacoUsadoMB,
    ((SUM(SYS.ALLOCATION_UNITS.total_pages) - SUM(SYS.ALLOCATION_UNITS.used_pages)) * 8) / 1024.0 AS EspacoNaoUsadoMB,

    SUM(SYS.ALLOCATION_UNITS.total_pages) * 8 AS EspacoTotalKB,
    SUM(SYS.ALLOCATION_UNITS.used_pages) * 8 AS EspacoUsadoKB,
    (SUM(SYS.ALLOCATION_UNITS.total_pages) - SUM(SYS.ALLOCATION_UNITS.used_pages)) * 8 AS EspacoNaoUsadoKB
	    
FROM SYS.TABLES  
INNER JOIN SYS.INDEXES ON SYS.TABLES.OBJECT_ID = SYS.INDEXES.object_id
INNER JOIN SYS.PARTITIONS ON SYS.INDEXES.object_id = SYS.PARTITIONS.OBJECT_ID AND SYS.INDEXES.index_id = SYS.PARTITIONS.index_id
INNER JOIN SYS.ALLOCATION_UNITS ON SYS.PARTITIONS.partition_id = SYS.ALLOCATION_UNITS.container_id
LEFT OUTER JOIN SYS.SCHEMAS ON SYS.TABLES.schema_id = SYS.SCHEMAS.schema_id
WHERE SYS.TABLES.NAME NOT LIKE 'dt%'
    AND SYS.TABLES.is_ms_shipped = 0
    AND SYS.TABLES.OBJECT_ID > 255
GROUP BY SYS.TABLES.Name, SYS.SCHEMAS.Name, SYS.PARTITIONS.Rows

GO

IF(NOT EXISTS(SELECT 1 FROM SYS.objects WHERE NAME = 'ERIS_Estrutura'))
CREATE TABLE ERIS_Estrutura(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Script] [varchar](400) NULL,
	[Primeira] [bit] NULL,
	[Tabela] [varchar](200) NULL,
	[Coluna] [varchar](200) NULL,
	[Interface] [varchar](400) NULL,
	[TabelaOrigem] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE PROC SP_InserirColunasIniciais
	@Tabela VARCHAR(200)
AS
	DECLARE @SQL VARCHAR(MAX)
	SET @SQL = REPLACE('IF NOT EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''@Tabela'') CREATE TABLE @Tabela (ID FLOAT PRIMARY KEY)','@Tabela', @Tabela)
	--PRINT @SQL
	SET NOCOUNT ON
	
	IF(NOT EXISTS(SELECT 1 FROM ERIS_Estrutura WHERE Script = @SQL))	
		INSERT INTO ERIS_Estrutura(Script, Primeira, Tabela)VALUES(@SQL, 1, @Tabela)
	
	EXEC (@SQL)
	
	SET @SQL = REPLACE('IF NOT EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''@Tabela'' AND Coluna = ''Codigo'') ALTER TABLE @Tabela ADD Codigo FLOAT','@Tabela', @Tabela)
	
	--PRINT @SQL
	
	IF(NOT EXISTS(SELECT 1 FROM ERIS_Estrutura WHERE Script = @SQL))	
		INSERT INTO ERIS_Estrutura(Script, Primeira, Tabela)VALUES(@SQL, 1, @Tabela)
	
	EXEC (@SQL)
	
	SET @SQL = REPLACE('IF NOT EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''@Tabela'' AND Coluna = ''ID_Entidade'') ALTER TABLE @Tabela ADD ID_Entidade FLOAT','@Tabela', @Tabela)
	--PRINT @SQL
	
	IF(NOT EXISTS(SELECT 1 FROM ERIS_Estrutura WHERE Script = @SQL))	
		INSERT INTO ERIS_Estrutura(Script, Primeira, Tabela)VALUES(@SQL, 1, @Tabela)
	
	EXEC (@SQL)
	SET NOCOUNT OFF
GO

CREATE PROC [dbo].[SP_TabelasFaltantes]
AS

DECLARE @Tabela VARCHAR(200)

SELECT  T.Tabela INTO #Temp FROM (SELECT REPLACE(Coluna,'ID_','') Tabela  FROM ERIS_Estrutura WHERE Coluna LIKE 'ID_%')T
LEFT JOIN ERIS_Estrutura ON T.Tabela = ERIS_Estrutura.Tabela
WHERE ERIS_Estrutura.Tabela IS NULL

WHILE(EXISTS(SELECT 1 FROM #Temp))
BEGIN
	SET @Tabela = (SELECT TOP 1 Tabela FROM #Temp)
	PRINT '
	SP_InserirColuna ' + @Tabela + '
	'
	DELETE FROM #Temp WHERE Tabela = @Tabela
END

DROP TABLE #Temp
GO

CREATE PROC SP_RemoverColunasFinais
	@Tabela VARCHAR(200)
AS
	DECLARE @SQL VARCHAR(MAX)

WHILE EXISTS(SELECT 1 FROM SYS.objects WHERE parent_object_id = OBJECT_ID('' + @Tabela + '') AND TYPE = 'D')
BEGIN
	SET @SQL = (SELECT TOP 1 'ALTER TABLE ' + @Tabela + ' DROP CONSTRAINT ' + name FROM SYS.objects WHERE parent_object_id = OBJECT_ID('' + @Tabela + '') AND TYPE = 'D')
	EXEC (@SQL)
END
	
	SET @SQL = REPLACE('
IF EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''@Tabela'' AND Coluna = ''ID_Base'') ALTER TABLE @Tabela DROP COLUMN ID_Base
IF EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''@Tabela'' AND Coluna = ''Ativo'') ALTER TABLE @Tabela DROP COLUMN Ativo
IF EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''@Tabela'' AND Coluna = ''DataCadastro'') ALTER TABLE @Tabela DROP COLUMN DataCadastro','@Tabela', @Tabela)
	
	DELETE FROM ERIS_Estrutura WHERE Tabela = @Tabela AND Primeira = 0
	
	EXEC (@SQL)

GO

CREATE PROC SP_InserirColunasFinais
	@Tabela VARCHAR(200)
AS
	DECLARE @SQL VARCHAR(MAX)
	
	EXEC SP_RemoverColunasFinais @Tabela
	
	SET @SQL = REPLACE('IF NOT EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''@Tabela'' AND Coluna = ''Ativo'') ALTER TABLE @Tabela ADD Ativo BIT','@Tabela', @Tabela)
	--PRINT @SQL
	
	IF(NOT EXISTS(SELECT 1 FROM ERIS_Estrutura WHERE Script = @SQL))
		INSERT INTO ERIS_Estrutura(Script, Primeira, Tabela)VALUES(@SQL, 0, @Tabela)

	EXEC (@SQL)

	SET @SQL = REPLACE('IF NOT EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''@Tabela'' AND Coluna = ''ID_Base'') ALTER TABLE @Tabela ADD ID_Base FLOAT','@Tabela', @Tabela)
	--PRINT @SQL
	
	IF(NOT EXISTS(SELECT 1 FROM ERIS_Estrutura WHERE Script = @SQL))
		INSERT INTO ERIS_Estrutura(Script, Primeira, Tabela)VALUES(@SQL, 0, @Tabela)
	EXEC (@SQL)

	SET @SQL = REPLACE('IF NOT EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''@Tabela'' AND Coluna = ''DataCadastro'') ALTER TABLE @Tabela ADD DataCadastro DATETIME DEFAULT GETDATE()','@Tabela', @Tabela)
	--PRINT @SQL
	
	IF(NOT EXISTS(SELECT 1 FROM ERIS_Estrutura WHERE Script = @SQL))
		INSERT INTO ERIS_Estrutura(Script, Primeira, Tabela)VALUES(@SQL, 0, @Tabela)
	EXEC (@SQL)
GO

CREATE PROC SP_MostrarEstrutura
	@Tabela VARCHAR(200)
AS
	DECLARE @ID INT = 0
	DECLARE @SQL VARCHAR(MAX)
	
	WHILE(EXISTS(SELECT 1 FROM ERIS_Estrutura WHERE Tabela = @Tabela AND ID > @ID))
	BEGIN
		SET @ID = (SELECT MIN(ID) FROM ERIS_Estrutura WHERE Tabela = @Tabela AND ID > @ID)
		SET @SQL = (SELECT Script FROM ERIS_Estrutura WHERE ID = @ID)	
		PRINT @SQL
	END
GO

CREATE PROC SP_InserirColuna
	@Tabela VARCHAR(200),
	@Coluna VARCHAR(200) = 'Descricao',
	@Tipo VARCHAR(200) = 'VARCHAR(150)',
	@AceitaNulo BIT = 1
AS
	DECLARE @SQL VARCHAR(MAX) 
	
	SET @Tabela = UPPER(LEFT(@Tabela,1)) + SUBSTRING(@Tabela, 2, 150)

	SET @Coluna = UPPER(LEFT(@Coluna,1)) + SUBSTRING(@Coluna, 2, 150)
		
	EXEC SP_InserirColunasIniciais @Tabela
	
	IF(@Coluna LIKE '%FONE%' OR @Coluna LIKE '%CELULAR%' OR @Coluna LIKE '%FAX%' OR @Coluna LIKE 'CodigoBarra%' OR @Coluna LIKE '%NumeroEndereco%')
		SET @Tipo = 'VARCHAR(15)'
	
	IF(@Coluna LIKE '%CPF%')
		SET @Tipo = 'VARCHAR(14)'	

	IF(@Coluna LIKE '%CNPJ%')
		SET @Tipo = 'VARCHAR(18)'
	
	IF(@Coluna LIKE 'ID_%' OR @Coluna LIKE 'Valor%')
		SET @Tipo = 'FLOAT'
	
	IF(@Coluna LIKE 'Data%')
		SET @Tipo = 'DATETIME'

	IF(@AceitaNulo = 1)
		SET @Tipo = UPPER(@Tipo) + ' NULL'
	ELSE
		SET @Tipo = UPPER(@Tipo) + ' NOT NULL'
	
	SET NOCOUNT ON
	DELETE FROM ERIS_Estrutura WHERE Tabela = @Tabela AND Coluna = @Coluna
	
	IF(EXISTS(SELECT 1 FROM VW_OMColunas WHERE TABELA = @Tabela AND COLUNA = @Coluna))
	BEGIN
		SET @SQL = 'ALTER TABLE ' + @Tabela + ' DROP COLUMN ' + @Coluna
		EXEC(@SQL)
	END
	
	SET @SQL = REPLACE(REPLACE(REPLACE('IF NOT EXISTS(SELECT 1 FROM VW_OMColunas WHERE Tabela = ''@Tabela'' AND Coluna = ''@Coluna'') ALTER TABLE @Tabela ADD @Coluna @Tipo','@Tabela', @Tabela), '@Tipo', @Tipo),'@Coluna', @Coluna)
	
	IF(NOT EXISTS(SELECT 1 FROM ERIS_Estrutura WHERE Script = @SQL))
		INSERT INTO ERIS_Estrutura(Script, Tabela, Coluna)VALUES(@SQL, @Tabela, @Coluna)

	EXEC (@SQL)
	
	EXEC SP_InserirColunasFinais @Tabela
	EXEC SP_MostrarEstrutura @Tabela
	EXEC SP_TabelasFaltantes
	SET NOCOUNT OFF
GO


CREATE FUNCTION Fn_PrimeirasMaiusculas(@Texto VARCHAR(5000))
RETURNS VARCHAR(5000)
BEGIN

	DECLARE @Retorno VARCHAR(5000) = ''
	DECLARE @Posicao INT
	DECLARE @Palavra VARCHAR(150)

	SET @Posicao = 0

	SET @Texto = LTRIM(RTRIM(LOWER(@Texto)))

	WHILE 1 = 1
	BEGIN
		SET @Posicao = CHARINDEX(' ', @Texto, @Posicao+1)

		IF @Posicao = 0
		BEGIN
			SET @Palavra = LTRIM(RTRIM(SUBSTRING(@Texto, LEN(@Retorno)+1, LEN(@Texto))))
			SET @Retorno = LTRIM(RTRIM(@Retorno + ' ' + UPPER(LEFT(@Palavra, 1)) + RIGHT(@Palavra, LEN(LTRIM(@Palavra))-1)))
			BREAK
		END
		ELSE
			SET @Palavra = LTRIM(RTRIM(SUBSTRING(@Texto, LEN(@Retorno)+1, @Posicao - LEN(@Retorno))))

		SET @Retorno = LTRIM(RTRIM(@Retorno + ' ' + UPPER(LEFT(@Palavra, 1)) + RIGHT(@Palavra, LEN(LTRIM(@Palavra))-1))) 
	END

	RETURN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
	@Retorno, ' DE ', ' de '), ' DA ', ' da '), ' DO ', ' do '), ' DAS ', ' das '), ' DOS ', ' dos ')
END
GO
