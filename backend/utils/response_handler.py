"""
Standardized API Response Handler
Provides consistent JSON response formatting across all API endpoints
"""
from flask import jsonify, Response
from typing import Any, Dict, Optional, Union, List
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class APIResponse:
    """Standardized API response builder"""
    
    @staticmethod
    def success(
        data: Any = None,
        message: Optional[str] = None,
        status_code: int = 200,
        meta: Optional[Dict[str, Any]] = None
    ) -> tuple[Response, int]:
        """
        Generate a standardized success response
        
        Args:
            data: Response data payload
            message: Optional success message
            status_code: HTTP status code (default: 200)
            meta: Optional metadata (pagination, etc.)
            
        Returns:
            Tuple of (JSON response, status code)
        """
        response = {
            'status': 'success',
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }
        
        if message:
            response['message'] = message
        
        if data is not None:
            # If data is a dict with 'message', merge it
            if isinstance(data, dict) and 'message' in data and not message:
                response['message'] = data.pop('message')
                response['data'] = data if data else None
            else:
                response['data'] = data
        
        if meta:
            response['meta'] = meta
        
        return jsonify(response), status_code
    
    @staticmethod
    def error(
        message: str,
        status_code: int = 400,
        error_code: Optional[str] = None,
        details: Optional[Union[str, Dict, List]] = None,
        field_errors: Optional[Dict[str, List[str]]] = None
    ) -> tuple[Response, int]:
        """
        Generate a standardized error response
        
        Args:
            message: Error message
            status_code: HTTP status code (default: 400)
            error_code: Optional error code for client handling
            details: Additional error details
            field_errors: Validation errors by field
            
        Returns:
            Tuple of (JSON response, status code)
        """
        response = {
            'status': 'error',
            'message': message,
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }
        
        if error_code:
            response['error_code'] = error_code
        
        if details:
            response['details'] = details
        
        if field_errors:
            response['field_errors'] = field_errors
        
        # Log error for debugging
        logger.error(
            f"API Error: {message} (status={status_code}, code={error_code})",
            extra={'details': details, 'field_errors': field_errors}
        )
        
        return jsonify(response), status_code
    
    @staticmethod
    def created(
        data: Any,
        message: str = "Resource created successfully",
        resource_id: Optional[str] = None
    ) -> tuple[Response, int]:
        """Shorthand for 201 Created response"""
        meta = {'resource_id': resource_id} if resource_id else None
        return APIResponse.success(data, message, 201, meta)
    
    @staticmethod
    def no_content() -> tuple[Response, int]:
        """Shorthand for 204 No Content response"""
        return jsonify({}), 204
    
    @staticmethod
    def not_found(
        resource: str = "Resource",
        resource_id: Optional[str] = None
    ) -> tuple[Response, int]:
        """Shorthand for 404 Not Found response"""
        message = f"{resource} not found"
        if resource_id:
            message += f" (ID: {resource_id})"
        return APIResponse.error(message, 404, 'RESOURCE_NOT_FOUND')
    
    @staticmethod
    def unauthorized(
        message: str = "Authentication required"
    ) -> tuple[Response, int]:
        """Shorthand for 401 Unauthorized response"""
        return APIResponse.error(message, 401, 'UNAUTHORIZED')
    
    @staticmethod
    def forbidden(
        message: str = "Access denied"
    ) -> tuple[Response, int]:
        """Shorthand for 403 Forbidden response"""
        return APIResponse.error(message, 403, 'FORBIDDEN')
    
    @staticmethod
    def validation_error(
        message: str = "Validation failed",
        field_errors: Optional[Dict[str, List[str]]] = None
    ) -> tuple[Response, int]:
        """Shorthand for 422 Validation Error response"""
        return APIResponse.error(
            message, 
            422, 
            'VALIDATION_ERROR',
            field_errors=field_errors
        )
    
    @staticmethod
    def internal_error(
        message: str = "Internal server error",
        error_id: Optional[str] = None
    ) -> tuple[Response, int]:
        """Shorthand for 500 Internal Server Error response"""
        details = {'error_id': error_id} if error_id else None
        return APIResponse.error(message, 500, 'INTERNAL_ERROR', details)


# Legacy function aliases for backward compatibility
def success_response(data: Any = None, status_code: int = 200) -> tuple[Response, int]:
    """
    Legacy success response (backward compatible)
    
    Deprecated: Use APIResponse.success() instead
    """
    return APIResponse.success(data, status_code=status_code)


def error_response(message: str, status_code: int = 400) -> tuple[Response, int]:
    """
    Legacy error response (backward compatible)
    
    Deprecated: Use APIResponse.error() instead
    """
    return APIResponse.error(message, status_code)
