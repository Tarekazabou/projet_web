// API configuration
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 
  (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:5000/api'
    : '/api');

export const API_ENDPOINTS = {
  // AI Recipes
  GENERATE_RECIPE: '/recipes/generate-with-ai',
  
  // Fridge
  FRIDGE_ITEMS: '/fridge/items',
  SUGGEST_RECIPES: '/fridge/suggest-recipes',
  
  // Meal Plans
  MEAL_PLANS: '/meal-plans',
  
  // Nutrition
  NUTRITION_LOGS: '/nutrition/logs',
  NUTRITION_GOALS: '/nutrition/goals',
  
  // Grocery Lists
  GROCERY_LISTS: '/grocery-lists',
  
  // Users
  USERS: '/users',
  USER_PREFERENCES: '/users/preferences',
  
  // Settings
  SETTINGS: '/settings',
  
  // Health Check
  HEALTH: '/health',
};
