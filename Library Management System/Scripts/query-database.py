#!/usr/bin/env python3
"""
Python script to query Shelf Check database
Can be run from your local machine or from the app pod
"""

import os
import sys
from sqlalchemy import create_engine, text
import pyodbc

# Database connection settings
DB_HOST = os.getenv('DB_HOST', 'mssql-service')
DB_USER = os.getenv('SQL_USER', 'SA')
DB_PASSWORD = os.getenv('SQL_PASSWORD', 'YourStrong!Passw0rd')
DB_NAME = os.getenv('SQL_DB', 'ShelfCheckDB')

def get_connection():
    """Create database connection"""
    drivers_to_try = [
        'ODBC Driver 18 for SQL Server',
        'ODBC Driver 17 for SQL Server'
    ]
    
    for driver in drivers_to_try:
        try:
            connection_string = (
                f'DRIVER={{{driver}}};'
                f'SERVER={DB_HOST};'
                f'DATABASE={DB_NAME};'
                f'UID={DB_USER};'
                f'PWD={DB_PASSWORD};'
                f'TrustServerCertificate=yes;'
            )
            conn = pyodbc.connect(connection_string)
            return conn
        except Exception as e:
            if driver == drivers_to_try[-1]:
                print(f"❌ Failed to connect: {e}")
                raise
            continue

def run_query(query, fetch_all=True):
    """Run a SQL query and return results"""
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(query)
        if fetch_all:
            columns = [column[0] for column in cursor.description]
            rows = cursor.fetchall()
            return columns, rows
        else:
            conn.commit()
            return None, None
    finally:
        conn.close()

def print_table(columns, rows):
    """Print query results in a table format"""
    if not rows:
        print("No results found.")
        return
    
    # Calculate column widths
    col_widths = [len(str(col)) for col in columns]
    for row in rows:
        for i, val in enumerate(row):
            col_widths[i] = max(col_widths[i], len(str(val) if val else ''))
    
    # Print header
    header = " | ".join(str(col).ljust(col_widths[i]) for i, col in enumerate(columns))
    print(header)
    print("-" * len(header))
    
    # Print rows
    for row in rows:
        print(" | ".join(str(val if val else '').ljust(col_widths[i]) for i, val in enumerate(row)))

def main():
    if len(sys.argv) > 1:
        # Run custom query
        query = " ".join(sys.argv[1:])
        print(f"Running query: {query}\n")
        try:
            columns, rows = run_query(query)
            if columns:
                print_table(columns, rows)
        except Exception as e:
            print(f"❌ Error: {e}")
        return
    
    # Interactive menu
    print("📊 Shelf Check Database Query Tool")
    print("=" * 40)
    print()
    print("1. List all tables")
    print("2. Show all users")
    print("3. Show all books")
    print("4. Show all book copies")
    print("5. Show all borrow transactions")
    print("6. Show database statistics")
    print("7. Custom SQL query")
    print("8. Exit")
    print()
    
    choice = input("Enter choice [1-8]: ").strip()
    
    queries = {
        "1": ("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME", "All Tables"),
        "2": ("SELECT user_id, username, email, role, created_at FROM users ORDER BY user_id", "All Users"),
        "3": ("SELECT book_id, title, author, isbn, category, created_at FROM books ORDER BY book_id", "All Books"),
        "4": ("SELECT copy_id, book_id, status, created_at FROM book_copies ORDER BY copy_id", "All Book Copies"),
        "5": ("SELECT transaction_id, user_id, copy_id, borrow_date, due_date, return_date FROM borrow_transactions ORDER BY transaction_id", "All Borrow Transactions"),
    }
    
    if choice == "6":
        print("\n📊 Database Statistics:")
        print("=" * 40)
        stats = [
            ("SELECT COUNT(*) as total_users FROM users", "Total Users"),
            ("SELECT COUNT(*) as total_books FROM books", "Total Books"),
            ("SELECT COUNT(*) as total_copies FROM book_copies", "Total Book Copies"),
            ("SELECT COUNT(*) as available FROM book_copies WHERE status = 'available'", "Available Copies"),
            ("SELECT COUNT(*) as borrowed FROM book_copies WHERE status = 'borrowed'", "Borrowed Copies"),
            ("SELECT COUNT(*) as active_borrows FROM borrow_transactions WHERE return_date IS NULL", "Active Borrows"),
        ]
        for query, label in stats:
            try:
                columns, rows = run_query(query)
                if rows:
                    print(f"{label}: {rows[0][0]}")
            except Exception as e:
                print(f"{label}: Error - {e}")
        print()
    elif choice == "7":
        query = input("\nEnter your SQL query: ").strip()
        print()
        try:
            columns, rows = run_query(query)
            if columns:
                print_table(columns, rows)
        except Exception as e:
            print(f"❌ Error: {e}")
    elif choice in queries:
        query, title = queries[choice]
        print(f"\n{title}:")
        print("=" * 40)
        try:
            columns, rows = run_query(query)
            if columns:
                print_table(columns, rows)
        except Exception as e:
            print(f"❌ Error: {e}")
    elif choice == "8":
        print("Goodbye!")
    else:
        print("Invalid choice")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

