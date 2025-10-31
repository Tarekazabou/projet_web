"""
Configuration Management for Mealy Backend
Centralized configuration with environment variable support and validation
"""
import os
from pathlib import Path
from typing import Any, Dict, List, Optional
from dotenv import load_dotenv
import logging

logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()


class ConfigurationError(Exception):
    """Raised when configuration is invalid or missing"""
    pass


class Config:
    """Base configuration class"""
    
    # Environment
    ENV = os.getenv('FLASK_ENV', 'development')
    DEBUG = ENV == 'development'
    TESTING = ENV == 'testing'
    
    # Server
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('PORT', 5000))
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    
    # Project paths
    BASE_DIR = Path(__file__).resolve().parent
    PROJECT_ROOT = BASE_DIR.parent
    DATA_DIR = BASE_DIR / 'data'
    LOGS_DIR = BASE_DIR / 'logs'
    
    # Firebase
    FIREBASE_PROJECT_ID = os.getenv('FIREBASE_PROJECT_ID', 'mealy-41bf0')
    FIREBASE_CREDENTIAL_PATH = os.getenv(
        'FIREBASE_CREDENTIAL_PATH',
        str(PROJECT_ROOT / 'mealy-41bf0-firebase-adminsdk-fbsvc-7d493e86ea.json')
    )
    
    # CORS
    CORS_ORIGINS = os.getenv(
        'CORS_ORIGINS',
        'http://localhost:3000,http://localhost:5000,http://127.0.0.1:5000'
    ).split(',')
    
    # AI Services
    GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
    GEMINI_MODEL = os.getenv('GEMINI_MODEL', 'gemini-2.0-flash-exp')
    GEMINI_EMBEDDING_MODEL = os.getenv('GEMINI_EMBEDDING_MODEL', 'models/text-embedding-004')
    
    # RAG Configuration
    RAG_RECIPES_CSV = os.getenv('RAG_RECIPES_CSV', str(PROJECT_ROOT / '13k-recipes.csv'))
    RAG_EMBEDDING_CACHE = os.getenv('RAG_EMBEDDING_CACHE', str(DATA_DIR / 'recipe_embeddings.npz'))
    RAG_MAX_EMBEDDED_RECIPES = int(os.getenv('RAG_MAX_EMBEDDED_RECIPES', '5000'))
    RAG_TOP_K = int(os.getenv('RAG_TOP_K', '5'))
    
    # Logging
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    LOG_FILE = LOGS_DIR / f'mealy_{ENV}.log'
    
    # Rate limiting
    RATE_LIMIT_ENABLED = os.getenv('RATE_LIMIT_ENABLED', 'true').lower() == 'true'
    RATE_LIMIT_DEFAULT = os.getenv('RATE_LIMIT_DEFAULT', '100 per hour')
    
    # Authentication
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', SECRET_KEY)
    JWT_ACCESS_TOKEN_EXPIRES = int(os.getenv('JWT_ACCESS_TOKEN_EXPIRES', '3600'))  # 1 hour
    JWT_REFRESH_TOKEN_EXPIRES = int(os.getenv('JWT_REFRESH_TOKEN_EXPIRES', '2592000'))  # 30 days
    
    # Demo mode
    DEMO_MODE_ENABLED = os.getenv('DEMO_MODE_ENABLED', 'true').lower() == 'true'
    DEMO_USER_ID = 'demo_user_01'
    
    @classmethod
    def validate(cls) -> None:
        """Validate configuration on startup"""
        errors = []
        
        # Check required directories
        cls.DATA_DIR.mkdir(parents=True, exist_ok=True)
        cls.LOGS_DIR.mkdir(parents=True, exist_ok=True)
        
        # Validate Firebase credentials
        if not Path(cls.FIREBASE_CREDENTIAL_PATH).exists():
            logger.warning(
                f"Firebase credential file not found at {cls.FIREBASE_CREDENTIAL_PATH}. "
                "Will attempt to use Application Default Credentials."
            )
        
        # Validate AI API keys
        if not cls.GEMINI_API_KEY:
            logger.warning(
                "GEMINI_API_KEY not set. AI recipe generation will not be available."
            )
        
        # Validate secret key in production
        if cls.ENV == 'production' and cls.SECRET_KEY == 'dev-secret-key-change-in-production':
            errors.append("SECRET_KEY must be set to a secure value in production")
        
        if errors:
            raise ConfigurationError(
                f"Configuration validation failed:\n" + "\n".join(f"  - {e}" for e in errors)
            )
        
        logger.info(f"Configuration validated successfully (ENV={cls.ENV})")
    
    @classmethod
    def get_dict(cls) -> Dict[str, Any]:
        """Get configuration as dictionary"""
        return {
            key: getattr(cls, key)
            for key in dir(cls)
            if not key.startswith('_') and not callable(getattr(cls, key))
        }
    
    @classmethod
    def summary(cls) -> str:
        """Get configuration summary (safe for logging)"""
        safe_config = cls.get_dict()
        
        # Redact sensitive values
        sensitive_keys = ['SECRET_KEY', 'JWT_SECRET_KEY', 'GEMINI_API_KEY']
        for key in sensitive_keys:
            if key in safe_config and safe_config[key]:
                safe_config[key] = '***REDACTED***'
        
        return "\n".join(f"{key}: {value}" for key, value in safe_config.items())


class DevelopmentConfig(Config):
    """Development environment configuration"""
    DEBUG = True
    TESTING = False


class ProductionConfig(Config):
    """Production environment configuration"""
    DEBUG = False
    TESTING = False
    
    # More strict CORS in production
    @classmethod
    def validate(cls) -> None:
        super().validate()
        
        # Additional production checks
        if 'localhost' in ','.join(cls.CORS_ORIGINS):
            logger.warning("localhost found in CORS_ORIGINS for production environment")


class TestingConfig(Config):
    """Testing environment configuration"""
    DEBUG = False
    TESTING = True
    
    # Use in-memory or test database
    FIREBASE_PROJECT_ID = 'mealy-test'


# Configuration factory
def get_config() -> Config:
    """Get configuration based on environment"""
    env = os.getenv('FLASK_ENV', 'development')
    
    config_map = {
        'development': DevelopmentConfig,
        'production': ProductionConfig,
        'testing': TestingConfig,
    }
    
    config_class = config_map.get(env, DevelopmentConfig)
    
    # Validate configuration
    try:
        config_class.validate()
    except ConfigurationError as e:
        logger.error(f"Configuration error: {e}")
        raise
    
    return config_class


# Singleton instance
config = get_config()
