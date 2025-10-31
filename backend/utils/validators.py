"""
Input Validation Utilities
Provides reusable validation functions and decorators for API endpoints
"""
from functools import wraps
from flask import request
from typing import Any, Callable, Dict, List, Optional, Set, Union
import re
import logging

from utils.response_handler import APIResponse

logger = logging.getLogger(__name__)


class ValidationError(Exception):
    """Raised when validation fails"""
    
    def __init__(self, message: str, field_errors: Optional[Dict[str, List[str]]] = None):
        super().__init__(message)
        self.field_errors = field_errors or {}


class Validator:
    """Common validation functions"""
    
    @staticmethod
    def required(value: Any, field_name: str) -> None:
        """Validate that a value is not None or empty"""
        if value is None or (isinstance(value, str) and not value.strip()):
            raise ValidationError(f"{field_name} is required")
    
    @staticmethod
    def email(value: str, field_name: str = "Email") -> None:
        """Validate email format"""
        if not value:
            raise ValidationError(f"{field_name} is required")
        
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, value):
            raise ValidationError(f"{field_name} must be a valid email address")
    
    @staticmethod
    def min_length(value: str, length: int, field_name: str) -> None:
        """Validate minimum string length"""
        if len(value) < length:
            raise ValidationError(f"{field_name} must be at least {length} characters")
    
    @staticmethod
    def max_length(value: str, length: int, field_name: str) -> None:
        """Validate maximum string length"""
        if len(value) > length:
            raise ValidationError(f"{field_name} must be no more than {length} characters")
    
    @staticmethod
    def min_value(value: Union[int, float], minimum: Union[int, float], field_name: str) -> None:
        """Validate minimum numeric value"""
        if value < minimum:
            raise ValidationError(f"{field_name} must be at least {minimum}")
    
    @staticmethod
    def max_value(value: Union[int, float], maximum: Union[int, float], field_name: str) -> None:
        """Validate maximum numeric value"""
        if value > maximum:
            raise ValidationError(f"{field_name} must be no more than {maximum}")
    
    @staticmethod
    def in_choices(value: Any, choices: Set[Any], field_name: str) -> None:
        """Validate value is in allowed choices"""
        if value not in choices:
            raise ValidationError(
                f"{field_name} must be one of: {', '.join(str(c) for c in choices)}"
            )
    
    @staticmethod
    def is_list(value: Any, field_name: str, min_items: int = 0) -> None:
        """Validate value is a list"""
        if not isinstance(value, list):
            raise ValidationError(f"{field_name} must be a list")
        if len(value) < min_items:
            raise ValidationError(f"{field_name} must contain at least {min_items} items")
    
    @staticmethod
    def is_dict(value: Any, field_name: str) -> None:
        """Validate value is a dictionary"""
        if not isinstance(value, dict):
            raise ValidationError(f"{field_name} must be an object")
    
    @staticmethod
    def positive_integer(value: Any, field_name: str) -> None:
        """Validate value is a positive integer"""
        if not isinstance(value, int) or value <= 0:
            raise ValidationError(f"{field_name} must be a positive integer")


def validate_json_body(required_fields: Optional[List[str]] = None) -> Callable:
    """
    Decorator to validate JSON request body
    
    Args:
        required_fields: List of required field names
    
    Returns:
        Decorated function
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Check Content-Type
            if not request.is_json:
                return APIResponse.error(
                    "Content-Type must be application/json",
                    400,
                    'INVALID_CONTENT_TYPE'
                )
            
            # Get JSON data
            try:
                data = request.get_json()
            except Exception as e:
                return APIResponse.error(
                    f"Invalid JSON: {str(e)}",
                    400,
                    'INVALID_JSON'
                )
            
            if data is None:
                return APIResponse.error(
                    "Request body is empty",
                    400,
                    'EMPTY_BODY'
                )
            
            # Check required fields
            if required_fields:
                field_errors = {}
                for field in required_fields:
                    if field not in data or data[field] is None:
                        field_errors[field] = [f"{field} is required"]
                    elif isinstance(data[field], str) and not data[field].strip():
                        field_errors[field] = [f"{field} cannot be empty"]
                
                if field_errors:
                    return APIResponse.validation_error(
                        "Missing required fields",
                        field_errors
                    )
            
            return func(*args, **kwargs)
        
        return wrapper
    return decorator


def validate_query_params(schema: Dict[str, Dict[str, Any]]) -> Callable:
    """
    Decorator to validate query parameters
    
    Args:
        schema: Dictionary defining parameter validation rules
                {
                    'param_name': {
                        'type': str|int|float|bool,
                        'required': bool,
                        'default': Any,
                        'choices': List[Any],
                        'min': int|float,
                        'max': int|float
                    }
                }
    
    Returns:
        Decorated function
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            field_errors = {}
            
            for param_name, rules in schema.items():
                value = request.args.get(param_name)
                
                # Handle required parameters
                if rules.get('required', False) and value is None:
                    field_errors[param_name] = [f"{param_name} is required"]
                    continue
                
                # Use default if not provided
                if value is None:
                    if 'default' in rules:
                        kwargs[param_name] = rules['default']
                    continue
                
                # Type conversion
                param_type = rules.get('type', str)
                try:
                    if param_type == bool:
                        value = value.lower() in ('true', '1', 'yes', 'on')
                    else:
                        value = param_type(value)
                except (ValueError, TypeError):
                    field_errors[param_name] = [
                        f"{param_name} must be of type {param_type.__name__}"
                    ]
                    continue
                
                # Validate choices
                if 'choices' in rules and value not in rules['choices']:
                    field_errors[param_name] = [
                        f"{param_name} must be one of: {', '.join(str(c) for c in rules['choices'])}"
                    ]
                    continue
                
                # Validate min/max for numeric types
                if param_type in (int, float):
                    if 'min' in rules and value < rules['min']:
                        field_errors[param_name] = [
                            f"{param_name} must be at least {rules['min']}"
                        ]
                        continue
                    if 'max' in rules and value > rules['max']:
                        field_errors[param_name] = [
                            f"{param_name} must be no more than {rules['max']}"
                        ]
                        continue
                
                kwargs[param_name] = value
            
            if field_errors:
                return APIResponse.validation_error(
                    "Invalid query parameters",
                    field_errors
                )
            
            return func(*args, **kwargs)
        
        return wrapper
    return decorator


def sanitize_input(text: str, max_length: int = 1000) -> str:
    """
    Sanitize user input to prevent XSS and injection attacks
    
    Args:
        text: Input text to sanitize
        max_length: Maximum allowed length
    
    Returns:
        Sanitized text
    """
    if not isinstance(text, str):
        return str(text)
    
    # Trim to max length
    text = text[:max_length]
    
    # Remove potentially dangerous characters (basic sanitization)
    # In production, consider using a library like bleach
    dangerous_patterns = [
        r'<script[^>]*>.*?</script>',
        r'javascript:',
        r'on\w+\s*=',
    ]
    
    for pattern in dangerous_patterns:
        text = re.sub(pattern, '', text, flags=re.IGNORECASE | re.DOTALL)
    
    return text.strip()


class RecipeValidator:
    """Specialized validators for recipe data"""
    
    DIFFICULTY_CHOICES = {'easy', 'medium', 'hard'}
    CUISINE_CHOICES = {
        'italian', 'chinese', 'mexican', 'indian', 'japanese',
        'french', 'thai', 'mediterranean', 'american', 'other'
    }
    
    @staticmethod
    def validate_recipe_data(data: Dict[str, Any]) -> None:
        """Validate recipe creation/update data"""
        errors = {}
        
        # Title
        if 'title' in data:
            try:
                Validator.required(data['title'], 'title')
                Validator.min_length(data['title'], 3, 'title')
                Validator.max_length(data['title'], 200, 'title')
            except ValidationError as e:
                errors['title'] = [str(e)]
        
        # Ingredients
        if 'ingredients' in data:
            try:
                Validator.is_list(data['ingredients'], 'ingredients', min_items=1)
            except ValidationError as e:
                errors['ingredients'] = [str(e)]
        
        # Instructions
        if 'instructions' in data:
            try:
                Validator.is_list(data['instructions'], 'instructions', min_items=1)
            except ValidationError as e:
                errors['instructions'] = [str(e)]
        
        # Difficulty
        if 'difficulty' in data:
            try:
                Validator.in_choices(
                    data['difficulty'],
                    RecipeValidator.DIFFICULTY_CHOICES,
                    'difficulty'
                )
            except ValidationError as e:
                errors['difficulty'] = [str(e)]
        
        # Servings
        if 'servingSize' in data or 'servings' in data:
            servings = data.get('servingSize') or data.get('servings')
            try:
                Validator.positive_integer(servings, 'servings')
                Validator.max_value(servings, 100, 'servings')
            except ValidationError as e:
                errors['servings'] = [str(e)]
        
        # Cooking time
        for time_field in ['prepTimeMinutes', 'cookTimeMinutes']:
            if time_field in data:
                try:
                    Validator.min_value(data[time_field], 0, time_field)
                    Validator.max_value(data[time_field], 1440, time_field)  # Max 24 hours
                except ValidationError as e:
                    errors[time_field] = [str(e)]
        
        if errors:
            raise ValidationError("Recipe validation failed", errors)
