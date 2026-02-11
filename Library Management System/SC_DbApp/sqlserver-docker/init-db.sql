-- Fast database initialization script
-- This runs automatically when SQL Server starts for the first time
-- Optimized for minimal execution time and faster startup

-- Create database with optimized settings for fast startup
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ShelfCheckDB')
BEGIN
    -- Create database with smaller initial sizes for faster creation
    CREATE DATABASE [ShelfCheckDB]
    ON 
    ( NAME = 'ShelfCheckDB', 
      FILENAME = '/var/opt/mssql/data/ShelfCheckDB.mdf', 
      SIZE = 32MB,  -- Smaller initial size for faster creation
      FILEGROWTH = 32MB,
      MAXSIZE = UNLIMITED )
    LOG ON 
    ( NAME = 'ShelfCheckDB_Log', 
      FILENAME = '/var/opt/mssql/data/ShelfCheckDB_Log.ldf', 
      SIZE = 16MB,  -- Smaller log file for faster creation
      FILEGROWTH = 16MB,
      MAXSIZE = UNLIMITED );
    
    -- Optimize database settings for faster startup and operations
    USE [ShelfCheckDB];
    GO
    
    -- Simple recovery model = faster startup (no log replay needed)
    ALTER DATABASE [ShelfCheckDB] SET RECOVERY SIMPLE;
    GO
    
    -- Disable auto-close for faster subsequent connections
    ALTER DATABASE [ShelfCheckDB] SET AUTO_CLOSE OFF;
    GO
    
    -- Disable auto-shrink (better performance)
    ALTER DATABASE [ShelfCheckDB] SET AUTO_SHRINK OFF;
    GO
    
    -- Enable snapshot isolation for better concurrency
    ALTER DATABASE [ShelfCheckDB] SET ALLOW_SNAPSHOT_ISOLATION ON;
    GO
    
    ALTER DATABASE [ShelfCheckDB] SET READ_COMMITTED_SNAPSHOT ON;
    GO
    
    -- Optimize for ad-hoc workloads (faster query compilation)
    ALTER DATABASE [ShelfCheckDB] SET PARAMETERIZATION SIMPLE;
    GO
    
    PRINT 'Database ShelfCheckDB created and optimized for fast startup';
END
ELSE
BEGIN
    PRINT 'Database ShelfCheckDB already exists - skipping creation';
END
GO

