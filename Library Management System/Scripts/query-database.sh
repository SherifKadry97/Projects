#!/bin/bash
# Script to query the Shelf Check database in Kubernetes

NAMESPACE="cls"
DB_POD_LABEL="app=mssql-db"

# Get database pod name
DB_POD=$(kubectl get pods -n $NAMESPACE -l $DB_POD_LABEL -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$DB_POD" ]; then
    echo "❌ Database pod not found"
    exit 1
fi

echo "📊 Connecting to database pod: $DB_POD"
echo ""

# Database credentials
DB_USER="SA"
DB_PASSWORD="YourStrong!Passw0rd"
DB_NAME="ShelfCheckDB"

# Function to run SQL query
run_query() {
    kubectl exec -n $NAMESPACE $DB_POD -- /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U $DB_USER \
        -P "$DB_PASSWORD" \
        -d $DB_NAME \
        -Q "$1" \
        -h -1 \
        -W \
        2>/dev/null
}

# If query provided as argument, run it
if [ ! -z "$1" ]; then
    echo "Running query: $1"
    echo ""
    run_query "$1"
    exit 0
fi

# Interactive menu
echo "What would you like to see?"
echo ""
echo "1. List all tables"
echo "2. Show all users"
echo "3. Show all books"
echo "4. Show all book copies"
echo "5. Show all borrow transactions"
echo "6. Show database statistics"
echo "7. Custom SQL query"
echo "8. Exit"
echo ""
read -p "Enter choice [1-8]: " choice

case $choice in
    1)
        echo ""
        echo "📋 All Tables:"
        echo "=============="
        run_query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME"
        ;;
    2)
        echo ""
        echo "👥 All Users:"
        echo "============="
        run_query "SELECT user_id, username, email, role, created_at FROM users ORDER BY user_id"
        ;;
    3)
        echo ""
        echo "📚 All Books:"
        echo "=============="
        run_query "SELECT book_id, title, author, isbn, category, created_at FROM books ORDER BY book_id"
        ;;
    4)
        echo ""
        echo "📖 All Book Copies:"
        echo "==================="
        run_query "SELECT copy_id, book_id, status, created_at FROM book_copies ORDER BY copy_id"
        ;;
    5)
        echo ""
        echo "📝 All Borrow Transactions:"
        echo "==========================="
        run_query "SELECT transaction_id, user_id, copy_id, borrow_date, due_date, return_date FROM borrow_transactions ORDER BY transaction_id"
        ;;
    6)
        echo ""
        echo "📊 Database Statistics:"
        echo "======================"
        echo ""
        echo "Total Users:"
        run_query "SELECT COUNT(*) as total_users FROM users"
        echo ""
        echo "Total Books:"
        run_query "SELECT COUNT(*) as total_books FROM books"
        echo ""
        echo "Total Book Copies:"
        run_query "SELECT COUNT(*) as total_copies FROM book_copies"
        echo ""
        echo "Available Copies:"
        run_query "SELECT COUNT(*) as available FROM book_copies WHERE status = 'available'"
        echo ""
        echo "Borrowed Copies:"
        run_query "SELECT COUNT(*) as borrowed FROM book_copies WHERE status = 'borrowed'"
        echo ""
        echo "Active Borrows:"
        run_query "SELECT COUNT(*) as active_borrows FROM borrow_transactions WHERE return_date IS NULL"
        ;;
    7)
        echo ""
        read -p "Enter your SQL query: " query
        echo ""
        echo "Results:"
        echo "========"
        run_query "$query"
        ;;
    8)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

