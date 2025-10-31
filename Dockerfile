# Use official Python runtime as base image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    FLASK_ENV=production

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY backend/requirements.txt /app/backend/requirements.txt

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install -r backend/requirements.txt

# Copy application code
COPY backend/ /app/backend/
COPY frontend/ /app/frontend/
COPY 13k-recipes.csv /app/13k-recipes.csv

# Copy Firebase credentials (use build arg for security)
ARG FIREBASE_CREDENTIALS
RUN if [ -n "$FIREBASE_CREDENTIALS" ]; then \
        echo "$FIREBASE_CREDENTIALS" > /app/firebase-credentials.json; \
    fi

# Create necessary directories
RUN mkdir -p /app/backend/data /app/backend/logs

# Set environment variable for credentials
ENV FIREBASE_CREDENTIAL_PATH=/app/firebase-credentials.json

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/api/health')"

# Run with Gunicorn (production WSGI server)
CMD ["gunicorn", \
     "--bind", "0.0.0.0:5000", \
     "--workers", "4", \
     "--threads", "2", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-level", "info", \
     "backend.src.app_enhanced:app"]
