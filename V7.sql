
CREATE VIEW Vw_ChecarRelacionamento

AS
--esta view foi criada para listar as colunas que possivelmente devam ser relacionadas, mas fogem da padronização de nomes
SELECT 
syscolumns.name Coluna,
sysobjects.name Tabela 
FROM SYScolumns 
INNER JOIN SYSOBJECTS ON syscolumns.id = sysobjects.id 
WHERE SYSCOLUMNS.name LIKE 'Codigo%' and SYSCOLUMNS.name <>'cODIGO'
AND SUBSTRING(SYSCOLUMNS.name,7,20) NOT IN(SELECT SYSOBJECTS.name FROM SYSOBJECTS WHERE XTYPE = 'U')
AND sysobjects.xtype = 'U'

GO
