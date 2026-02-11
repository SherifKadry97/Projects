from app import db
from datetime import datetime
# (NEW) Import password hashing functions
from werkzeug.security import generate_password_hash, check_password_hash

# --- User Model ---
class User(db.Model):
    __tablename__ = 'users'
    user_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    role = db.Column(db.String(50), nullable=False, default='user')
    
    transactions = db.relationship('BorrowTransaction', back_populates='borrower')

    # (NEW) Method to set password
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    # (NEW) Method to check password
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def __repr__(self):
        return f'<User {self.username}>'

# (No changes to the other models)
# --- Book Model ---
class Book(db.Model):
    __tablename__ = 'book'
    book_id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    author = db.Column(db.String(200), nullable=False)
    # (NEW) Book category for grouping in admin dashboard
    category = db.Column(db.String(100), nullable=True, index=True)
    isbn = db.Column(db.String(20), unique=True, nullable=True)
    available_copies = db.Column(db.Integer, nullable=False, default=0)
    copies = db.relationship(
        'BookCopy',
        back_populates='book',
        cascade="all, delete-orphan",
        passive_deletes=True
    )
    def __repr__(self):
        return f'<Book {self.title}>'

# --- BookCopy Model ---
class BookCopy(db.Model):
    __tablename__ = 'book_copy'
    copy_id = db.Column(db.Integer, primary_key=True)
    book_id = db.Column(db.Integer, db.ForeignKey('book.book_id', ondelete="CASCADE"), nullable=False)
    status = db.Column(db.String(20), default='available', nullable=False)
    book = db.relationship('Book', back_populates='copies')
    transactions = db.relationship('BorrowTransaction', back_populates='book_copy', cascade="all, delete-orphan", passive_deletes=True)
    def __repr__(self):
        return f'<Copy {self.copy_id} (Book: {self.book_id})>'

# --- BorrowTransaction Model ---
class BorrowTransaction(db.Model):
    __tablename__ = 'borrow_transaction'
    borrow_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.user_id'), nullable=False)
    copy_id = db.Column(db.Integer, db.ForeignKey('book_copy.copy_id', ondelete="CASCADE"), nullable=False)
    borrow_date = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    due_date = db.Column(db.DateTime, nullable=False)
    return_date = db.Column(db.DateTime, nullable=True)
    borrower = db.relationship('User', back_populates='transactions')
    book_copy = db.relationship('BookCopy', back_populates='transactions')
    def __repr__(self):
        return f'<Transaction {self.borrow_id}>'