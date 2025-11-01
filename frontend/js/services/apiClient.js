/**
 * API Client Service
 * Centralized API communication layer
 */

class ApiClient {
    constructor() {
        this.baseUrl = this.getApiBaseUrl();
        this.defaultHeaders = {
            'Content-Type': 'application/json'
        };
    }

    getApiBaseUrl() {
        if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
            return 'http://localhost:5000/api';
        }
        return '/api';
    }

    /**
     * Generic request handler
     */
    async request(endpoint, options = {}) {
        const url = `${this.baseUrl}${endpoint}`;
        const config = {
            ...options,
            headers: {
                ...this.defaultHeaders,
                ...options.headers
            }
        };

        try {
            const response = await fetch(url, config);
            const data = await response.json();

            if (!response.ok) {
                // Extract error message from response
                const errorMessage = data.error || data.message || `API Error: ${response.status}`;
                throw new Error(errorMessage);
            }

            // Return the data property if it exists (success_response format)
            return data.data || data;
        } catch (error) {
            console.error(`API Request failed: ${endpoint}`, error);
            throw error;
        }
    }

    // ===== CONVENIENCE METHODS =====
    
    get(endpoint) {
        return this.request(endpoint, { method: 'GET' });
    }

    post(endpoint, body) {
        return this.request(endpoint, {
            method: 'POST',
            body: JSON.stringify(body)
        });
    }

    put(endpoint, body) {
        return this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(body)
        });
    }

    delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    }

    // ===== RECIPE ENDPOINTS =====
    
    async getRecipes(params = {}) {
        // Use AI recipes list endpoint instead of old search
        const queryString = new URLSearchParams(params).toString();
        const endpoint = queryString ? `/recipes/list?${queryString}` : '/recipes/list';
        return this.get(endpoint);
    }

    async getRecipeById(id) {
        return this.get(`/recipes/${id}`);
    }

    async generateRecipes(params) {
        return this.post('/ai-recipes/generate', params);
    }

    // ===== FRIDGE ENDPOINTS =====
    
    async getFridgeItems() {
        return this.get('/fridge/items');
    }

    async addFridgeItem(item) {
        return this.post('/fridge/items', item);
    }

    async updateFridgeItem(id, updates) {
        return this.put(`/fridge/items/${id}`, updates);
    }

    async deleteFridgeItem(id) {
        return this.delete(`/fridge/items/${id}`);
    }

    async suggestRecipesFromFridge(options = {}) {
        return this.post('/fridge/suggest-recipes', options);
    }

    // ===== MEAL PLAN ENDPOINTS =====
    
    async getMealPlans() {
        return this.get('/meal-plans');
    }

    async createMealPlan(plan) {
        return this.post('/meal-plans', plan);
    }

    async updateMealPlan(id, updates) {
        return this.put(`/meal-plans/${id}`, updates);
    }

    async deleteMealPlan(id) {
        return this.delete(`/meal-plans/${id}`);
    }

    // ===== NUTRITION ENDPOINTS =====
    
    async getNutritionLog(date) {
        return this.get(`/nutrition/log?date=${date}`);
    }

    async logMeal(meal) {
        return this.post('/nutrition/log', meal);
    }

    async getNutritionGoals() {
        return this.get('/nutrition/goals');
    }

    async updateNutritionGoals(goals) {
        return this.put('/nutrition/goals', goals);
    }

    // ===== GROCERY LIST ENDPOINTS =====
    
    async getGroceryLists() {
        return this.get('/grocery');
    }

    async createGroceryList(list) {
        return this.post('/grocery', list);
    }

    async updateGroceryList(id, updates) {
        return this.put(`/grocery/${id}`, updates);
    }

    async deleteGroceryList(id) {
        return this.delete(`/grocery/${id}`);
    }

    // ===== USER ENDPOINTS =====
    
    async getUserPreferences() {
        return this.get('/users/preferences');
    }

    async updateUserPreferences(preferences) {
        return this.put('/users/preferences', preferences);
    }

    // ===== SETTINGS ENDPOINTS =====
    
    async checkApiKeyStatus() {
        return this.get('/settings/api-key/status');
    }

    async testApiKey(apiKey) {
        return this.post('/settings/api-key/test', { api_key: apiKey });
    }

    async saveApiKey(apiKey) {
        return this.post('/settings/api-key', { api_key: apiKey });
    }
}

// Export singleton instance
window.apiClient = new ApiClient();
