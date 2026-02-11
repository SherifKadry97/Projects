# Optimized SQL Server Docker Image

This custom SQL Server image is optimized for **faster startup times**.

## Optimizations Applied:

1. **Express Edition**: Lighter weight than Developer edition
2. **SQL Agent Disabled**: Saves startup time
3. **Memory Limits**: Configured for faster memory allocation
4. **Optimized Database Settings**:
   - Simple recovery model (no log replay on startup)
   - Auto-close disabled (faster connections)
   - Snapshot isolation enabled
   - Smaller initial file sizes for faster creation

5. **Automatic Database Initialization**: 
   - Database is created automatically on first startup
   - No need for app to wait and create it manually
   - Runs as soon as SQL Server is ready

## Expected Startup Time:

- **First startup**: ~30-45 seconds (creates database)
- **Subsequent startups**: ~15-25 seconds (database exists)

## Usage:

The database `ShelfCheckDB` will be automatically created when the container starts for the first time. The Flask app only needs to wait for SQL Server to be ready, not for database creation.

## Files:

- `Dockerfile`: Custom SQL Server image with init scripts
- `init-db.sql`: Database initialization script (runs automatically)
- `docker-entrypoint.sh`: Optional startup optimization script

