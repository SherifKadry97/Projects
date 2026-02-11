#!/bin/bash
# Quick database viewer - simple and working

NAMESPACE="cls"
APP_POD=$(kubectl get pods -n $NAMESPACE -l app=shelf-check,component=web -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$APP_POD" ]; then
    echo "❌ Application pod not found"
    exit 1
fi

echo "📊 Database Contents"
echo "==================="
echo ""

# Users
echo "👥 USERS:"
echo "---------"
kubectl exec -n $NAMESPACE $APP_POD -- python3 -c "
from sqlalchemy import create_engine, text
import os
uri = f'mssql+pyodbc://{os.getenv(\"SQL_USER\")}:{os.getenv(\"SQL_PASSWORD\")}@{os.getenv(\"DB_HOST\")}:1433/{os.getenv(\"SQL_DB\")}?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes'
engine = create_engine(uri)
with engine.connect() as conn:
    result = conn.execute(text('SELECT user_id, username, email, role FROM [user] ORDER BY user_id'))
    print('ID | Username | Email | Role')
    print('-' * 50)
    for row in result:
        print(f'{row[0]} | {row[1]} | {row[2]} | {row[3]}')
" 2>/dev/null || echo "No users found"
echo ""

# Books
echo "📚 BOOKS:"
echo "---------"
kubectl exec -n $NAMESPACE $APP_POD -- python3 -c "
from sqlalchemy import create_engine, text
import os
uri = f'mssql+pyodbc://{os.getenv(\"SQL_USER\")}:{os.getenv(\"SQL_PASSWORD\")}@{os.getenv(\"DB_HOST\")}:1433/{os.getenv(\"SQL_DB\")}?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes'
engine = create_engine(uri)
with engine.connect() as conn:
    result = conn.execute(text('SELECT book_id, title, author, isbn FROM book ORDER BY book_id'))
    count = 0
    for row in result:
        if count == 0:
            print('ID | Title | Author | ISBN')
            print('-' * 60)
        print(f'{row[0]} | {row[1]} | {row[2]} | {row[3]}')
        count += 1
    if count == 0:
        print('No books found')
" 2>/dev/null
echo ""

# Statistics
echo "📊 STATISTICS:"
echo "-------------"
kubectl exec -n $NAMESPACE $APP_POD -- python3 -c "
from sqlalchemy import create_engine, text
import os
uri = f'mssql+pyodbc://{os.getenv(\"SQL_USER\")}:{os.getenv(\"SQL_PASSWORD\")}@{os.getenv(\"DB_HOST\")}:1433/{os.getenv(\"SQL_DB\")}?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes'
engine = create_engine(uri)
with engine.connect() as conn:
    users = conn.execute(text('SELECT COUNT(*) FROM [user]')).scalar()
    books = conn.execute(text('SELECT COUNT(*) FROM book')).scalar()
    copies = conn.execute(text('SELECT COUNT(*) FROM book_copy')).scalar()
    available = conn.execute(text('SELECT COUNT(*) FROM book_copy WHERE status = \\'available\\'')).scalar()
    borrowed = conn.execute(text('SELECT COUNT(*) FROM book_copy WHERE status = \\'borrowed\\'')).scalar()
    transactions = conn.execute(text('SELECT COUNT(*) FROM borrow_transaction')).scalar()
    active = conn.execute(text('SELECT COUNT(*) FROM borrow_transaction WHERE return_date IS NULL')).scalar()
    print(f'Total Users: {users}')
    print(f'Total Books: {books}')
    print(f'Total Copies: {copies}')
    print(f'  - Available: {available}')
    print(f'  - Borrowed: {borrowed}')
    print(f'Total Transactions: {transactions}')
    print(f'Active Borrows: {active}')
" 2>/dev/null

