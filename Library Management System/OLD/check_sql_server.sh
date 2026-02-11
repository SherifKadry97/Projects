#!/bin/bash
# Script to check if SQL Server container is ready

echo "Checking SQL Server container status..."
docker ps -a | grep mssql_db

echo ""
echo "Checking SQL Server logs (last 50 lines)..."
docker logs mssql_db --tail 50

echo ""
echo "Checking if SQL Server port is accessible..."
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/localhost/1433' 2>/dev/null && echo "✅ Port 1433 is open" || echo "❌ Port 1433 is not accessible"

echo ""
echo "Checking container health..."
docker inspect mssql_db --format='{{.State.Status}} - Health: {{.State.Health.Status}}' 2>/dev/null || echo "Container not found or healthcheck not configured"

