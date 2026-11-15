-- Mismo usuario y permisos del script manual, con contraseña de entorno sqlcmd.
USE master;
GO
IF SUSER_ID(N'globalfrio_backend') IS NULL
    CREATE LOGIN globalfrio_backend WITH PASSWORD = '$(DB_CLAVE)', CHECK_POLICY = ON;
GO
USE globalfrio_db;
GO
IF DATABASE_PRINCIPAL_ID(N'globalfrio_backend') IS NULL
    CREATE USER globalfrio_backend FOR LOGIN globalfrio_backend;
IF ISNULL(IS_ROLEMEMBER(N'db_datareader', N'globalfrio_backend'), 0) <> 1
    ALTER ROLE db_datareader ADD MEMBER globalfrio_backend;
IF ISNULL(IS_ROLEMEMBER(N'db_datawriter', N'globalfrio_backend'), 0) <> 1
    ALTER ROLE db_datawriter ADD MEMBER globalfrio_backend;
GO
