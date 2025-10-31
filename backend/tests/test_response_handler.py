"""
Tests for Response Handler
Test standardized API response formatting
"""
import pytest
from utils.response_handler import APIResponse, success_response, error_response


class TestAPIResponse:
    """Test APIResponse class"""
    
    def test_success_response_with_data(self):
        """Test success response with data"""
        response, status_code = APIResponse.success({'id': '123', 'name': 'Test'})
        
        assert status_code == 200
        assert response.json['status'] == 'success'
        assert 'timestamp' in response.json
        assert response.json['data']['id'] == '123'
        assert response.json['data']['name'] == 'Test'
    
    def test_success_response_with_message(self):
        """Test success response with message"""
        response, status_code = APIResponse.success(
            {'id': '123'}, 
            message='Operation successful'
        )
        
        assert status_code == 200
        assert response.json['status'] == 'success'
        assert response.json['message'] == 'Operation successful'
        assert response.json['data']['id'] == '123'
    
    def test_success_response_with_meta(self):
        """Test success response with metadata"""
        response, status_code = APIResponse.success(
            {'items': []},
            meta={'page': 1, 'total': 10}
        )
        
        assert status_code == 200
        assert response.json['meta']['page'] == 1
        assert response.json['meta']['total'] == 10
    
    def test_error_response(self):
        """Test error response"""
        response, status_code = APIResponse.error(
            'Something went wrong',
            400,
            'ERROR_CODE'
        )
        
        assert status_code == 400
        assert response.json['status'] == 'error'
        assert response.json['message'] == 'Something went wrong'
        assert response.json['error_code'] == 'ERROR_CODE'
        assert 'timestamp' in response.json
    
    def test_error_response_with_details(self):
        """Test error response with details"""
        response, status_code = APIResponse.error(
            'Validation failed',
            422,
            'VALIDATION_ERROR',
            details={'field': 'email', 'issue': 'invalid format'}
        )
        
        assert status_code == 422
        assert response.json['details']['field'] == 'email'
    
    def test_error_response_with_field_errors(self):
        """Test error response with field errors"""
        field_errors = {
            'email': ['Email is required', 'Email must be valid'],
            'password': ['Password too short']
        }
        response, status_code = APIResponse.error(
            'Validation failed',
            422,
            field_errors=field_errors
        )
        
        assert status_code == 422
        assert len(response.json['field_errors']['email']) == 2
        assert len(response.json['field_errors']['password']) == 1
    
    def test_created_response(self):
        """Test 201 Created response"""
        response, status_code = APIResponse.created(
            {'id': 'new_123'},
            resource_id='new_123'
        )
        
        assert status_code == 201
        assert response.json['status'] == 'success'
        assert response.json['message'] == 'Resource created successfully'
        assert response.json['meta']['resource_id'] == 'new_123'
    
    def test_no_content_response(self):
        """Test 204 No Content response"""
        response, status_code = APIResponse.no_content()
        
        assert status_code == 204
        assert response.json == {}
    
    def test_not_found_response(self):
        """Test 404 Not Found response"""
        response, status_code = APIResponse.not_found('Recipe', 'recipe_123')
        
        assert status_code == 404
        assert response.json['status'] == 'error'
        assert 'Recipe not found' in response.json['message']
        assert 'recipe_123' in response.json['message']
        assert response.json['error_code'] == 'RESOURCE_NOT_FOUND'
    
    def test_unauthorized_response(self):
        """Test 401 Unauthorized response"""
        response, status_code = APIResponse.unauthorized()
        
        assert status_code == 401
        assert response.json['error_code'] == 'UNAUTHORIZED'
        assert 'Authentication required' in response.json['message']
    
    def test_forbidden_response(self):
        """Test 403 Forbidden response"""
        response, status_code = APIResponse.forbidden()
        
        assert status_code == 403
        assert response.json['error_code'] == 'FORBIDDEN'
        assert 'Access denied' in response.json['message']
    
    def test_validation_error_response(self):
        """Test 422 Validation Error response"""
        field_errors = {'email': ['Invalid email']}
        response, status_code = APIResponse.validation_error(
            field_errors=field_errors
        )
        
        assert status_code == 422
        assert response.json['error_code'] == 'VALIDATION_ERROR'
        assert response.json['field_errors'] == field_errors
    
    def test_internal_error_response(self):
        """Test 500 Internal Server Error response"""
        response, status_code = APIResponse.internal_error(
            error_id='err_123'
        )
        
        assert status_code == 500
        assert response.json['error_code'] == 'INTERNAL_ERROR'
        assert response.json['details']['error_id'] == 'err_123'


class TestLegacyFunctions:
    """Test backward compatible legacy functions"""
    
    def test_legacy_success_response(self):
        """Test legacy success_response function"""
        response, status_code = success_response({'id': '123'})
        
        assert status_code == 200
        assert response.json['status'] == 'success'
        assert response.json['data']['id'] == '123'
    
    def test_legacy_error_response(self):
        """Test legacy error_response function"""
        response, status_code = error_response('Error occurred', 400)
        
        assert status_code == 400
        assert response.json['status'] == 'error'
        assert response.json['message'] == 'Error occurred'
