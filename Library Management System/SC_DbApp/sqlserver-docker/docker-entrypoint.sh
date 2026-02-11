#!/bin/bash
# Optimized SQL Server startup script

# Set SQL Server to use minimal resources for faster startup
export MSSQL_MEMORY_LIMIT_MB=${MSSQL_MEMORY_LIMIT_MB:-2048}

# Start SQL Server in the background with optimized settings
# The container's default entrypoint will handle initialization scripts
exec /opt/mssql/bin/sqlservr

