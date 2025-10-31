"""
Flask Middleware
Custom middleware for request/response processing, logging, and authentication
"""
import time
import uuid
from flask import Flask, request, g
from typing import Callable
import logging

logger = logging.getLogger(__name__)


class RequestIDMiddleware:
    """Add unique request ID to each request for tracing"""
    
    def __init__(self, app: Flask):
        self.app = app
        app.before_request(self.before_request)
        app.after_request(self.after_request)
    
    def before_request(self):
        """Generate request ID before processing"""
        g.request_id = request.headers.get('X-Request-ID', str(uuid.uuid4()))
        g.start_time = time.time()
    
    def after_request(self, response):
        """Add request ID to response headers"""
        if hasattr(g, 'request_id'):
            response.headers['X-Request-ID'] = g.request_id
        return response


class RequestLoggingMiddleware:
    """Log all incoming requests and responses"""
    
    def __init__(self, app: Flask):
        self.app = app
        app.before_request(self.log_request)
        app.after_request(self.log_response)
    
    def log_request(self):
        """Log incoming request details"""
        logger.info(
            f"Request started: {request.method} {request.path}",
            extra={
                'request_id': getattr(g, 'request_id', None),
                'method': request.method,
                'path': request.path,
                'remote_addr': request.remote_addr,
                'user_agent': request.user_agent.string if request.user_agent else None,
            }
        )
    
    def log_response(self, response):
        """Log response details and request duration"""
        if hasattr(g, 'start_time'):
            duration = time.time() - g.start_time
            
            logger.info(
                f"Request completed: {request.method} {request.path} - {response.status_code} ({duration:.3f}s)",
                extra={
                    'request_id': getattr(g, 'request_id', None),
                    'method': request.method,
                    'path': request.path,
                    'status_code': response.status_code,
                    'duration': duration,
                }
            )
        
        return response


class CORSMiddleware:
    """Enhanced CORS handling"""
    
    def __init__(self, app: Flask, allowed_origins: list):
        self.app = app
        self.allowed_origins = allowed_origins
        app.after_request(self.add_cors_headers)
    
    def add_cors_headers(self, response):
        """Add CORS headers to response"""
        origin = request.headers.get('Origin')
        
        if origin in self.allowed_origins or '*' in self.allowed_origins:
            response.headers['Access-Control-Allow-Origin'] = origin or self.allowed_origins[0]
            response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
            response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Request-ID'
            response.headers['Access-Control-Allow-Credentials'] = 'true'
            response.headers['Access-Control-Max-Age'] = '3600'
        
        return response


class SecurityHeadersMiddleware:
    """Add security headers to all responses"""
    
    def __init__(self, app: Flask):
        self.app = app
        app.after_request(self.add_security_headers)
    
    def add_security_headers(self, response):
        """Add security headers"""
        # Prevent clickjacking
        response.headers['X-Frame-Options'] = 'SAMEORIGIN'
        
        # Prevent MIME sniffing
        response.headers['X-Content-Type-Options'] = 'nosniff'
        
        # Enable XSS protection
        response.headers['X-XSS-Protection'] = '1; mode=block'
        
        # Referrer policy
        response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        
        # Content Security Policy (basic)
        response.headers['Content-Security-Policy'] = (
            "default-src 'self'; "
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.gstatic.com; "
            "style-src 'self' 'unsafe-inline'; "
            "img-src 'self' data: https:; "
            "font-src 'self' data:; "
            "connect-src 'self' https://firestore.googleapis.com https://generativelanguage.googleapis.com"
        )
        
        return response


class RateLimitMiddleware:
    """Simple in-memory rate limiting (for production, use Redis)"""
    
    def __init__(self, app: Flask, max_requests: int = 100, window: int = 3600):
        self.app = app
        self.max_requests = max_requests
        self.window = window  # seconds
        self.requests = {}  # {ip: [(timestamp, count)]}
        app.before_request(self.check_rate_limit)
    
    def check_rate_limit(self):
        """Check if request exceeds rate limit"""
        from flask import jsonify
        
        # Skip rate limiting for health check
        if request.path == '/api/health':
            return None
        
        ip = request.remote_addr
        now = time.time()
        
        # Clean old entries
        if ip in self.requests:
            self.requests[ip] = [
                (ts, count) for ts, count in self.requests[ip]
                if now - ts < self.window
            ]
        else:
            self.requests[ip] = []
        
        # Count requests in window
        total_requests = sum(count for _, count in self.requests[ip])
        
        if total_requests >= self.max_requests:
            logger.warning(
                f"Rate limit exceeded for IP {ip}",
                extra={'ip': ip, 'requests': total_requests}
            )
            return jsonify({
                'status': 'error',
                'message': 'Rate limit exceeded. Please try again later.',
                'error_code': 'RATE_LIMIT_EXCEEDED'
            }), 429
        
        # Record this request
        self.requests[ip].append((now, 1))
        
        return None


def setup_middleware(app: Flask, config) -> None:
    """
    Initialize all middleware for the Flask app
    
    Args:
        app: Flask application instance
        config: Application configuration
    """
    # Request ID tracking
    RequestIDMiddleware(app)
    
    # Request/Response logging
    if config.DEBUG or config.ENV != 'testing':
        RequestLoggingMiddleware(app)
    
    # Security headers
    SecurityHeadersMiddleware(app)
    
    # Rate limiting (disabled in development/testing)
    if config.RATE_LIMIT_ENABLED and config.ENV == 'production':
        RateLimitMiddleware(app, max_requests=100, window=3600)
    
    logger.info("Middleware initialized successfully")
