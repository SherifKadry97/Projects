import os
from app import create_app

# This name 'flask_app' matches your error log
flask_app = create_app()

if __name__ == '__main__':
    # Run on all interfaces (0.0.0.0) so it's accessible from outside the container
    # Use PORT environment variable if set, otherwise default to 5000
    port = int(os.environ.get('PORT', 5000))
    flask_app.run(host='0.0.0.0', port=port, debug=False)
