"""
Logging Configuration
Centralized logging setup with structured logging and multiple handlers
"""
import logging
import logging.handlers
import sys
import json
from pathlib import Path
from datetime import datetime
from typing import Any, Dict


class JSONFormatter(logging.Formatter):
    """Format logs as JSON for structured logging"""
    
    def format(self, record: logging.LogRecord) -> str:
        """Format log record as JSON"""
        log_data = {
            'timestamp': datetime.utcfromtimestamp(record.created).isoformat() + 'Z',
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno,
        }
        
        # Add exception info if present
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)
        
        # Add extra fields
        if hasattr(record, 'request_id'):
            log_data['request_id'] = record.request_id
        
        if hasattr(record, 'user_id'):
            log_data['user_id'] = record.user_id
        
        # Add any custom fields from extra parameter
        for key, value in record.__dict__.items():
            if key not in ('name', 'msg', 'args', 'created', 'filename', 'funcName',
                          'levelname', 'levelno', 'lineno', 'module', 'msecs',
                          'message', 'pathname', 'process', 'processName',
                          'relativeCreated', 'thread', 'threadName', 'exc_info',
                          'exc_text', 'stack_info', 'request_id', 'user_id'):
                try:
                    json.dumps(value)  # Test if value is JSON serializable
                    log_data[key] = value
                except (TypeError, ValueError):
                    log_data[key] = str(value)
        
        return json.dumps(log_data)


class ColoredConsoleFormatter(logging.Formatter):
    """Colored formatter for console output"""
    
    # ANSI color codes
    COLORS = {
        'DEBUG': '\033[36m',     # Cyan
        'INFO': '\033[32m',      # Green
        'WARNING': '\033[33m',   # Yellow
        'ERROR': '\033[31m',     # Red
        'CRITICAL': '\033[35m',  # Magenta
    }
    RESET = '\033[0m'
    
    def format(self, record: logging.LogRecord) -> str:
        """Format with colors"""
        color = self.COLORS.get(record.levelname, self.RESET)
        record.levelname = f"{color}{record.levelname}{self.RESET}"
        
        return super().format(record)


def setup_logging(config) -> None:
    """
    Configure logging for the application
    
    Args:
        config: Application configuration object
    """
    # Create logs directory if it doesn't exist
    config.LOGS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Get root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, config.LOG_LEVEL.upper()))
    
    # Remove existing handlers
    root_logger.handlers.clear()
    
    # Console handler (colored for development)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.DEBUG if config.DEBUG else logging.INFO)
    
    if config.DEBUG:
        console_formatter = ColoredConsoleFormatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
    else:
        console_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
    
    console_handler.setFormatter(console_formatter)
    root_logger.addHandler(console_handler)
    
    # File handler for general logs
    file_handler = logging.handlers.RotatingFileHandler(
        config.LOG_FILE,
        maxBytes=10 * 1024 * 1024,  # 10 MB
        backupCount=5,
        encoding='utf-8'
    )
    file_handler.setLevel(logging.INFO)
    
    if config.ENV == 'production':
        # Use JSON format for production logs
        file_formatter = JSONFormatter()
    else:
        file_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
    
    file_handler.setFormatter(file_formatter)
    root_logger.addHandler(file_handler)
    
    # Separate error log file
    error_file = config.LOGS_DIR / f'mealy_{config.ENV}_errors.log'
    error_handler = logging.handlers.RotatingFileHandler(
        error_file,
        maxBytes=10 * 1024 * 1024,  # 10 MB
        backupCount=5,
        encoding='utf-8'
    )
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(file_formatter)
    root_logger.addHandler(error_handler)
    
    # Reduce noise from third-party libraries
    logging.getLogger('werkzeug').setLevel(logging.WARNING)
    logging.getLogger('urllib3').setLevel(logging.WARNING)
    logging.getLogger('google').setLevel(logging.WARNING)
    
    root_logger.info(
        f"Logging configured successfully (level={config.LOG_LEVEL}, env={config.ENV})"
    )


class RequestLogger:
    """Helper class for structured request logging"""
    
    @staticmethod
    def log_request_start(method: str, path: str, **kwargs):
        """Log request start"""
        logger = logging.getLogger('request')
        logger.info(
            f"Request started: {method} {path}",
            extra=kwargs
        )
    
    @staticmethod
    def log_request_end(method: str, path: str, status_code: int, duration: float, **kwargs):
        """Log request completion"""
        logger = logging.getLogger('request')
        logger.info(
            f"Request completed: {method} {path} - {status_code} ({duration:.3f}s)",
            extra={'status_code': status_code, 'duration': duration, **kwargs}
        )
    
    @staticmethod
    def log_error(method: str, path: str, error: Exception, **kwargs):
        """Log request error"""
        logger = logging.getLogger('request')
        logger.error(
            f"Request failed: {method} {path} - {type(error).__name__}: {str(error)}",
            exc_info=True,
            extra=kwargs
        )


class AILogger:
    """Helper class for AI service logging"""
    
    @staticmethod
    def log_generation_start(prompt_length: int, **kwargs):
        """Log AI generation start"""
        logger = logging.getLogger('ai')
        logger.info(
            f"AI generation started (prompt_length={prompt_length})",
            extra={'prompt_length': prompt_length, **kwargs}
        )
    
    @staticmethod
    def log_generation_end(duration: float, success: bool, **kwargs):
        """Log AI generation completion"""
        logger = logging.getLogger('ai')
        level = logging.INFO if success else logging.WARNING
        logger.log(
            level,
            f"AI generation completed (duration={duration:.2f}s, success={success})",
            extra={'duration': duration, 'success': success, **kwargs}
        )
    
    @staticmethod
    def log_rag_retrieval(query: str, num_results: int, strategy: str, **kwargs):
        """Log RAG retrieval"""
        logger = logging.getLogger('rag')
        logger.info(
            f"RAG retrieval: {num_results} results (strategy={strategy})",
            extra={
                'query': query[:100],  # Truncate long queries
                'num_results': num_results,
                'strategy': strategy,
                **kwargs
            }
        )
