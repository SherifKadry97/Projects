#!/bin/bash
# Simple script to view database contents using the app pod

NAMESPACE="cls"
APP_POD=$(kubectl get pods -n $NAMESPACE -l app=shelf-check,component=web -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$APP_POD" ]; then
    echo "❌ Application pod not found"
    exit 1
fi

echo "📊 Querying database via app pod: $APP_POD"
echo ""

# Function to run Python query
run_python_query() {
    local query="$1"
    kubectl exec -n $NAMESPACE $APP_POD -- python3 <<EOF
import os
from sqlalchemy import create_engine, text

DB_USER = os.getenv('SQL_USER', 'SA')
DB_PASS = os.getenv('SQL_PASSWORD', 'YourStrong!Passw0rd')
DB_NAME = os.getenv('SQL_DB', 'ShelfCheckDB')
DB_HOST = os.getenv('DB_HOST', 'mssql-service')

try:
    uri = f'mssql+pyodbc://{DB_USER}:{DB_PASS}@{DB_HOST}:1433/{DB_NAME}?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes'
    engine = create_engine(uri)
    with engine.connect() as conn:
        result = conn.execute(text('''$query'''))
        rows = result.fetchall()
        if rows:
            # Get column names
            columns = result.keys()
            # Print header
            print(' | '.join(str(col) for col in columns))
            print('-' * 60)
            # Print rows
            for row in rows:
                print(' | '.join(str(val) if val is not None else 'NULL' for val in row))
        else:
            print('No results found')
except Exception as e:
    print(f'Error: {e}')
EOF
}

# Menu
echo "What would you like to see?"
echo ""
echo "1. List all tables"
echo "2. Show all users"
echo "3. Show all books"
echo "4. Show all book copies"
echo "5. Show all borrow transactions"
echo "6. Show database statistics"
echo "7. Exit"
echo ""
read -p "Enter choice [1-7]: " choice

case $choice in
    1)
        echo ""
        run_python_query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME"
        ;;
    2)
        echo ""
        run_python_query "SELECT user_id, username, email, role, created_at FROM [user] ORDER BY user_id"
        ;;
    3)
        echo ""
        run_python_query "SELECT book_id, title, author, isbn, category, created_at FROM book ORDER BY book_id"
        ;;
    4)
        echo ""
        run_python_query "SELECT copy_id, book_id, status, created_at FROM book_copy ORDER BY copy_id"
        ;;
    5)
        echo ""
        run_python_query "SELECT transaction_id, user_id, copy_id, borrow_date, due_date, return_date FROM borrow_transaction ORDER BY transaction_id"
        ;;
    6)
        echo ""
        echo "📊 Database Statistics:"
        echo "======================"
        echo ""
        echo "Total Users:"
        run_python_query "SELECT COUNT(*) as total_users FROM [user]"
        echo ""
        echo "Total Books:"
        run_python_query "SELECT COUNT(*) as total_books FROM book"
        echo ""
        echo "Total Book Copies:"
        run_python_query "SELECT COUNT(*) as total_copies FROM book_copy"
        echo ""
        echo "Available Copies:"
        run_python_query "SELECT COUNT(*) as available FROM book_copy WHERE status = 'available'"
        echo ""
        echo "Borrowed Copies:"
        run_python_query "SELECT COUNT(*) as borrowed FROM book_copy WHERE status = 'borrowed'"
        echo ""
        echo "Active Borrows:"
        run_python_query "SELECT COUNT(*) as active_borrows FROM borrow_transaction WHERE return_date IS NULL"
        ;;
    7)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

