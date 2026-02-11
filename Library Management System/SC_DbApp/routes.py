from flask import render_template, request, flash, redirect, url_for, session
from models import User, Book, BookCopy, BorrowTransaction
from sqlalchemy import func
from datetime import datetime, timedelta
import random
from flask import jsonify
from sqlalchemy import text

def register_routes(app, db):
    CATEGORY_CHOICES = [
        'Fiction',
        'Fantasy',
        'Science Fiction',
        'Mystery',
        'Romance',
        'Nonfiction',
        'Biography',
        'Self-Help',
        'History'
    ]

    def generate_unique_isbn():
        def check_digit(prefix):
            total = 0
            for idx, ch in enumerate(prefix):
                val = int(ch)
                total += val if idx % 2 == 0 else 3 * val
            return str((10 - (total % 10)) % 10)

        while True:
            body = '978' + ''.join(str(random.randint(0, 9)) for _ in range(9))
            isbn_candidate = body + check_digit(body)
            if not Book.query.filter_by(isbn=isbn_candidate).first():
                return isbn_candidate
    
    # ---------- HOME ----------
    @app.route("/health")
    def health():
        return jsonify({"status": "ok"}), 200

    @app.route("/health/db")
    def health_db():
        try:
            # Execute lightweight query
            db.session.execute(text("SELECT 1"))
            return jsonify({
                "database": "connected",
                "status": "ok"
            }), 200

        except Exception as e:
            return jsonify({
                "database": "error",
                "status": "failed",
                "error": str(e)
            }), 500
    @app.route('/')
    def index():
        return render_template('index.html')

    # ---------- LOGIN ----------
    @app.route('/login', methods=['GET', 'POST'])
    def login():
        session.pop('_flashes', None)
        if request.method == 'POST':
            username = request.form['username']
            password = request.form['password']
            
            user = User.query.filter_by(username=username).first()
            
            if user and user.check_password(password):
                session['user_id'] = user.user_id
                session['username'] = user.username
                session['role'] = user.role
                
                if user.role == 'admin':
                    flash('Login successful! Welcome, Admin.', 'success')
                    return redirect(url_for('admin_dashboard'))
                else:
                    flash('Login successful! Welcome!', 'success')
                    return redirect(url_for('user_dashboard'))
            else:
                flash('Invalid username or password.', 'error')
                return render_template('login.html')

        return render_template('login.html')
    
    # ---------- SIGN UP ----------
    @app.route('/signup', methods=['GET', 'POST'])
    def signup():
        if request.method == 'POST':
            username = (request.form.get('username') or '').strip()
            email = (request.form.get('email') or '').strip()
            password = (request.form.get('password') or '').strip()

            if not username or not email or not password:
                flash('All fields are required.', 'error')
                return render_template('signup.html', username=username, email=email)

            # Check if username or email already exists
            if User.query.filter((User.username == username) | (User.email == email)).first():
                flash('Username or email already taken.', 'error')
                return render_template('signup.html', username=username, email=email)

            try:
                new_user = User(username=username, email=email, role='user')
                new_user.set_password(password)
                db.session.add(new_user)
                db.session.commit()
                flash('User created successfully! You can now log in.', 'success')
                return redirect(url_for('login'))
            except Exception as e:
                db.session.rollback()
                flash(f'Failed to create user: {e}', 'error')
                return render_template('signup.html', username=username, email=email)

        return render_template('signup.html')

    # ---------- USER DASHBOARD ----------
    @app.route('/user/dashboard', methods=['GET', 'POST'])
    def user_dashboard():
        if 'role' not in session or session['role'] != 'user':
            flash('Please log in as a user to access this page.', 'error')
            return redirect(url_for('login'))

        user_id = session['user_id']

        # Handle Borrow POST
        if request.method == 'POST':
            book_id = request.form.get('book_id')
            due_date_str = request.form.get('due_date')

            try:
                due_date = datetime.strptime(due_date_str, "%Y-%m-%d")
            except Exception:
                flash('Invalid date format.', 'error')
                return redirect(url_for('user_dashboard'))

            max_due_date = datetime.utcnow() + timedelta(days=14)
            if due_date > max_due_date:
                flash('Due date cannot exceed 2 weeks from today.', 'error')
                return redirect(url_for('user_dashboard'))

            available_copy = BookCopy.query.filter_by(book_id=book_id, status='available').first()
            if not available_copy:
                flash('This book is currently unavailable.', 'error')
                return redirect(url_for('user_dashboard'))

            try:
                available_copy.status = 'borrowed'

                # Decrement book count
                book = Book.query.get(available_copy.book_id)
                if book.available_copies > 0:
                    book.available_copies -= 1

                # Create transaction
                transaction = BorrowTransaction(
                    copy_id=available_copy.copy_id,
                    user_id=user_id,
                    borrow_date=datetime.now(),
                    due_date=due_date
                )
                db.session.add(transaction)
                db.session.commit()
                flash(f'You borrowed "{book.title}". Due on {due_date:%Y-%m-%d}.', 'success')
            except Exception as e:
                db.session.rollback()
                flash(f'Error processing borrow request: {e}', 'error')

            return redirect(url_for('user_dashboard'))

        # GET request — list all books
        all_books = Book.query.all()
        category_to_books = {}
        for b in all_books:
            key = b.category or 'Uncategorized'
            category_to_books.setdefault(key, []).append(b)

        return render_template(
            'user_dashboard.html',
            username=session.get('username'),
            category_to_books=category_to_books
        )

    # ---------- ADMIN DASHBOARD ----------
    @app.route('/admin/dashboard')
    def admin_dashboard():
        if 'role' not in session or session['role'] != 'admin':
            flash('You do not have permission to view this page.', 'error')
            return redirect(url_for('login'))

        try:
            all_users = User.query.all()
            all_books = Book.query.all()
            all_copies = BookCopy.query.all()
            active_borrows = BorrowTransaction.query.filter_by(return_date=None).all()

            category_to_books_full = {}
            book_availability = {}

            if not all_books:
                flash("No books found in the database.", "info")

            # ✅ iterate safely
            for book in all_books:
                if not book:
                    continue  # skip any malformed record

                key = book.category or 'Uncategorized'
                category_to_books_full.setdefault(key, []).append(book)

                try:
                    available_count = (
                        BookCopy.query.filter_by(book_id=book.book_id, status='available').count()
                    )
                except Exception:
                    available_count = 0  # fail-safe fallback if book_id is missing

                book_availability[book.book_id] = available_count

            category_options = sorted(category_to_books_full.keys())
            selected_category = request.args.get('category', '')

            if selected_category and selected_category in category_to_books_full:
                category_to_books = {selected_category: category_to_books_full[selected_category]}
            else:
                category_to_books = category_to_books_full
                selected_category = ''

            return render_template(
                'admin_page.html',
                users=all_users,
                books=all_books,
                copies=all_copies,
                borrows=active_borrows,
                category_to_books=category_to_books,
                category_options=category_options,
                selected_category=selected_category,
                book_availability=book_availability
            )

        except Exception as e:
            db.session.rollback()
            flash(f"Error accessing database: {e}", 'error')
            return f"An error occurred: {e}", 500


    # ---------- ADD BOOK ----------
    @app.route('/admin/books/new', methods=['GET', 'POST'])
    def add_book():
        if 'role' not in session or session['role'] != 'admin':
            flash('You do not have permission to view this page.', 'error')
            return redirect(url_for('login'))

        if request.method == 'POST':
            title = (request.form.get('title') or '').strip()
            author = (request.form.get('author') or '').strip()
            category_value = (request.form.get('category') or '').strip()
            category = category_value if category_value else None
            try:
                num_copies = int(request.form.get('num_copies', 1))
                if num_copies < 1:
                    num_copies = 1
            except (ValueError, TypeError):
                num_copies = 1

            if not title or not author:
                flash('Title and Author are required.', 'error')
                return render_template(
                    'add_book.html',
                    categories=CATEGORY_CHOICES,
                    title=title,
                    author=author,
                    category=category_value,
                    num_copies=num_copies
                )

            if category and category not in CATEGORY_CHOICES:
                flash('Please choose a valid category.', 'error')
                return render_template(
                    'add_book.html',
                    categories=CATEGORY_CHOICES,
                    title=title,
                    author=author,
                    category=category_value,
                    num_copies=num_copies
                )

            try:
                isbn = generate_unique_isbn()
                # Create book
                new_book = Book(title=title, author=author, category=category, isbn=isbn)
                db.session.add(new_book)
                db.session.commit()

                # Create requested number of available copies
                for _ in range(num_copies):
                    db.session.add(BookCopy(book_id=new_book.book_id, status='available'))
                new_book.available_copies = num_copies
                db.session.commit()

                flash(f'Book added successfully with {num_copies} available copy(ies).', 'success')
                return redirect(url_for('admin_dashboard'))
            except Exception as e:
                db.session.rollback()
                flash(f'Failed to add book: {e}', 'error')
                return render_template(
                    'add_book.html',
                    categories=CATEGORY_CHOICES,
                    title=title,
                    author=author,
                    category=category_value,
                    num_copies=num_copies
                )

        return render_template('add_book.html', categories=CATEGORY_CHOICES)

    # ---------- EDIT BOOK ----------
    @app.route('/admin/books/<int:book_id>/edit', methods=['GET', 'POST'])
    def edit_book(book_id):
        if 'role' not in session or session['role'] != 'admin':
            flash('You do not have permission to view this page.', 'error')
            return redirect(url_for('login'))

        book = Book.query.get_or_404(book_id)

        if request.method == 'POST':
            title = (request.form.get('title') or '').strip()
            author = (request.form.get('author') or '').strip()
            category_value = (request.form.get('category') or '').strip()
            category = category_value if category_value else None

            if not title or not author:
                flash('Title and Author are required.', 'error')
                return render_template('edit_book.html', book=book, categories=CATEGORY_CHOICES)

            if category and category not in CATEGORY_CHOICES:
                flash('Please choose a valid category.', 'error')
                return render_template(
                    'edit_book.html',
                    book=book,
                    categories=CATEGORY_CHOICES,
                    title=title,
                    author=author,
                    category=category_value
                )

            try:
                book.title = title
                book.author = author
                book.category = category
                db.session.commit()
                flash('Book updated successfully.', 'success')
                return redirect(url_for('admin_dashboard'))
            except Exception as e:
                db.session.rollback()
                flash(f'Failed to update book: {e}', 'error')
                return render_template(
                    'edit_book.html',
                    book=book,
                    categories=CATEGORY_CHOICES,
                    title=title,
                    author=author,
                    category=category_value
                )

        return render_template('edit_book.html', book=book, categories=CATEGORY_CHOICES)

    # ---------- DELETE BOOK ----------
    @app.route('/admin/books/<int:book_id>/delete', methods=['POST'])
    def delete_book(book_id):
        if 'role' not in session or session['role'] != 'admin':
            flash('You do not have permission to perform this action.', 'error')
            return redirect(url_for('login'))

        book = Book.query.get_or_404(book_id)
        try:
            db.session.delete(book)
            db.session.commit()
            flash('Book removed.', 'success')
        except Exception as e:
            db.session.rollback()
            flash(f'Failed to remove book: {e}', 'error')
        return redirect(url_for('admin_dashboard'))

    # ---------- LOGOUT ----------
    @app.route('/logout')
    def logout():
        session.pop('user_id', None)
        session.pop('username', None)
        session.pop('role', None)
        flash('You have been logged out.', 'success')
        return redirect(url_for('login'))

    # ---------- CREATE ADMIN ----------
    @app.route('/create_admin')
    def create_admin():
        if User.query.filter_by(username='admin').first():
            return 'Admin user already exists.'
        admin_user = User(username='admin', email='admin@library.com', role='admin')
        admin_user.set_password('password123')
        db.session.add(admin_user)
        db.session.commit()
        return 'Admin user "admin" with password "password123" created!'
    # ---------- MY BOOKS ----------
    @app.route('/user/my_books')
    def my_books():
        if 'role' not in session or session['role'] != 'user':
            flash('Please log in as a user to access this page.', 'error')
            return redirect(url_for('login'))

        user_id = session['user_id']
        borrows = BorrowTransaction.query.filter_by(user_id=user_id).order_by(BorrowTransaction.borrow_date.desc()).all()
        current_time = datetime.utcnow()

        return render_template(
            'my_books.html',
            username=session.get('username'),
            borrows=borrows,
            now=current_time  # ✅ Pass actual datetime, not a function
        )
    
    # ---------- RETURN BOOK ----------
    @app.route('/user/return/<int:borrow_id>', methods=['POST'])
    def return_book(borrow_id):
        if 'role' not in session or session['role'] != 'user':
            flash('Please log in as a user to perform this action.', 'error')
            return redirect(url_for('login'))

        transaction = BorrowTransaction.query.get_or_404(borrow_id)

        if transaction.user_id != session['user_id']:
            flash('You cannot modify another user’s borrow record.', 'error')
            return redirect(url_for('my_books'))

        try:
            transaction.book_copy.status = 'available'
            book = transaction.book_copy.book
            book.available_copies += 1
            db.session.delete(transaction)
            db.session.commit()
            flash(f'Book "{book.title}" returned successfully.', 'success')
        except Exception as e:
            db.session.rollback()
            flash(f'Failed to return book: {e}', 'error')

        return redirect(url_for('my_books'))



