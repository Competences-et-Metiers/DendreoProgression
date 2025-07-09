FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create logs directory
RUN mkdir -p logs

# Create a startup script
RUN echo '#!/bin/bash\n\
echo "Starting FastAPI application..."\n\
echo "Waiting for database to be ready..."\n\
python -c "from app.models.database import engine; from sqlalchemy import text; import time; import sys; \
attempts = 0; \
while attempts < 30: \
    try: \
        with engine.connect() as conn: \
            conn.execute(text('\''SELECT 1'\'')); \
        print('\''Database is ready!'\''); \
        break; \
    except Exception as e: \
        print(f'\''Database not ready yet: {e}'\''); \
        attempts += 1; \
        time.sleep(2); \
else: \
    print('\''Database connection failed after 30 attempts'\''); \
    sys.exit(1)"\n\
echo "Creating database tables..."\n\
python -c "from app.models.database import create_tables; create_tables()"\n\
echo "Starting uvicorn server..."\n\
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload\n\
' > /app/start.sh && chmod +x /app/start.sh

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Run the startup script
CMD ["/app/start.sh"]