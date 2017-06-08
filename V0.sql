
DROP TABLE Cliente
DROP TABLE Vendedor
GO

CREATE TABLE Cliente
(
	ID INT PRIMARY KEY,
	Cleinte VARCHAR(50),
)

CREATE TABLE Vendedor
(
	ID INT PRIMARY KEY,
	Vendedor VARCHAR(50),
)

INSERT INTO Cliente VALUES(1, 'João')
INSERT INTO Cliente VALUES(2, 'Antonio')
INSERT INTO Cliente VALUES(3, 'Pedro')
INSERT INTO Cliente VALUES(4, 'Maria')

INSERT INTO Vendedor VALUES(3, 'Roberto')
INSERT INTO Vendedor VALUES(4, 'Alfredo')
INSERT INTO Vendedor VALUES(5, 'Fábio')
INSERT INTO Vendedor VALUES(6, 'Geraldo')

SELECT*FROM Cliente
SELECT*FROM Vendedor
GO

SELECT*FROM Cliente
INNER JOIN Vendedor ON Cliente.ID = Vendedor.ID

GO
SELECT*FROM Cliente
LEFT JOIN Vendedor ON Cliente.ID = Vendedor.ID
GO

SELECT*FROM Cliente
RIGHT JOIN Vendedor ON Cliente.ID = Vendedor.ID
GO

SELECT*FROM Cliente
LEFT JOIN Vendedor ON Cliente.ID = Vendedor.ID
WHERE Vendedor.ID IS NULL
GO

SELECT*FROM Cliente
RIGHT JOIN Vendedor ON Cliente.ID = Vendedor.ID
WHERE Cliente.ID IS NULL
GO

SELECT*FROM Cliente
FULL OUTER JOIN Vendedor ON Cliente.ID = Vendedor.ID
GO

SELECT*FROM Cliente
FULL OUTER JOIN Vendedor ON Cliente.ID = Vendedor.ID
WHERE Cliente.ID IS NULL OR Vendedor.ID IS NULL
GO

SELECT*FROM Cliente
CROSS JOIN Vendedor 
GO


