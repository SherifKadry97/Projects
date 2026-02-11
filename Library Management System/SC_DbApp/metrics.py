"""
Prometheus metrics for Shelf Check application
"""
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from flask import Response
from functools import wraps
import time

# HTTP request metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total number of HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

# Application-specific metrics
books_total = Gauge(
    'books_total',
    'Total number of books in the library'
)

book_copies_available = Gauge(
    'book_copies_available',
    'Number of available book copies'
)

book_copies_borrowed = Gauge(
    'book_copies_borrowed',
    'Number of borrowed book copies'
)

users_total = Gauge(
    'users_total',
    'Total number of users'
)

active_borrows = Gauge(
    'active_borrows',
    'Number of active borrow transactions'
)

database_connections = Gauge(
    'database_connections',
    'Number of active database connections'
)

database_query_duration_seconds = Histogram(
    'database_query_duration_seconds',
    'Database query duration in seconds',
    ['query_type']
)


def track_request_metrics(f):
    """Decorator to track HTTP request metrics"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        start_time = time.time()
        method = 'GET'  # Default, can be enhanced to get from request
        endpoint = f.__name__
        
        try:
            response = f(*args, **kwargs)
            status = '200' if hasattr(response, 'status_code') else '200'
            http_requests_total.labels(method=method, endpoint=endpoint, status=status).inc()
            return response
        except Exception as e:
            status = '500'
            http_requests_total.labels(method=method, endpoint=endpoint, status=status).inc()
            raise
        finally:
            duration = time.time() - start_time
            http_request_duration_seconds.labels(method=method, endpoint=endpoint).observe(duration)
    
    return decorated_function


def update_application_metrics(db):
    """Update application-specific metrics from database"""
    try:
        from models import Book, BookCopy, User, BorrowTransaction
        
        # Count books
        books_count = Book.query.count()
        books_total.set(books_count)
        
        # Count available copies
        available_copies = BookCopy.query.filter_by(status='available').count()
        book_copies_available.set(available_copies)
        
        # Count borrowed copies
        borrowed_copies = BookCopy.query.filter_by(status='borrowed').count()
        book_copies_borrowed.set(borrowed_copies)
        
        # Count users
        users_count = User.query.count()
        users_total.set(users_count)
        
        # Count active borrows
        active_borrows_count = BorrowTransaction.query.filter_by(return_date=None).count()
        active_borrows.set(active_borrows_count)
        
    except Exception as e:
        # Silently fail metrics update to not break the app
        print(f"Warning: Failed to update metrics: {e}")


def get_metrics():
    """Return Prometheus metrics"""
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


