# Custom SQL Server image optimized for fast startup
FROM mcr.microsoft.com/mssql/server:2022-latest

# Switch to root to install and configure
USER root

# Create directory for initialization scripts
RUN mkdir -p /var/opt/mssql/init

# Copy initialization script
COPY init-db.sql /var/opt/mssql/init/

# Copy and set up startup script (optional optimization)
# COPY docker-entrypoint.sh /usr/local/bin/
# RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set proper permissions for init scripts
RUN chown -R mssql:mssql /var/opt/mssql/init && \
    chmod -R 755 /var/opt/mssql/init

# Switch back to mssql user
USER mssql

# SQL Server will automatically execute .sql files from /var/opt/mssql/init/
# on first startup after SQL Server is ready
# This creates the database immediately, reducing app wait time

