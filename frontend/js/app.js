// ===== MAIN APPLICATION CONTROLLER =====
class RecipeMealPlannerApp {
    constructor() {
        this.apiBase = '/api';
        this.currentUser = null;
        this.currentPage = 'home';
        
        // Initialize specialized components
        this.yourFridge = new YourFridge(this);
        this.recipeGenerator = new RecipeGenerator(this);
        this.mealPlanner = new MealPlanner(this);
        this.nutritionTracker = new NutritionTracker(this);
        this.groceryListManager = new GroceryListManager(this);
        
        // Initialize app
        this.init();
    }
    
    async init() {
        // Set up event listeners
        this.setupEventListeners();
        
        // Load initial data
        await this.loadInitialData();
        
        // Initialize components
        this.initializeComponents();
        
        // Set current date
        this.setCurrentDate();
        
        console.log('Recipe Meal Planner App initialized');
    }
    
    setupEventListeners() {
        // Navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const page = e.target.dataset.page;
                if (page) {
                    this.navigateToPage(page);
                }
            });
        });
        
        // Modal controls
        document.querySelectorAll('.modal-close').forEach(closeBtn => {
            closeBtn.addEventListener('click', () => {
                this.closeModal(closeBtn.closest('.modal'));
            });
        });
        
        // Click outside modal to close
        document.querySelectorAll('.modal').forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    this.closeModal(modal);
                }
            });
        });
        
        // User preferences button
        document.getElementById('user-preferences-btn')?.addEventListener('click', () => {
            this.openPreferencesModal();
        });
        
        // User profile button
        document.getElementById('user-profile-btn')?.addEventListener('click', () => {
            this.openUserProfile();
        });
        
        // Hero action buttons
        document.querySelector('[data-action="start-cooking"]')?.addEventListener('click', () => {
            this.navigateToPage('recipe-generator');
        });
        
        document.querySelector('[data-action="explore-recipes"]')?.addEventListener('click', () => {
            this.navigateToPage('recipe-generator');
        });
        
        // View all recipes button
        document.getElementById('view-all-recipes')?.addEventListener('click', () => {
            this.navigateToPage('recipe-generator');
        });
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeAllModals();
            }
        });
    }
    
    async loadInitialData() {
        try {
            // Load popular recipes for homepage
            await this.loadPopularRecipes();
            
            // Load app statistics
            await this.loadAppStats();
            
            // Check for existing user session
            await this.checkUserSession();
            
        } catch (error) {
            console.error('Error loading initial data:', error);
            this.showToast('Failed to load initial data', 'error');
        }
    }
    
    async loadPopularRecipes() {
        try {
            const response = await fetch(`${this.apiBase}/recipes/search?sort_by=rating&per_page=6`);
            const data = await response.json();
            
            if (data.recipes) {
                this.renderPopularRecipes(data.recipes);
            }
        } catch (error) {
            console.error('Error loading popular recipes:', error);
        }
    }
    
    renderPopularRecipes(recipes) {
        const container = document.getElementById('popular-recipes-grid');
        if (!container) return;
        
        container.innerHTML = recipes.map(recipe => this.createRecipeCard(recipe)).join('');
        
        // Add click listeners to recipe cards
        container.querySelectorAll('.recipe-card').forEach(card => {
            card.addEventListener('click', () => {
                const recipeId = card.dataset.recipeId;
                this.openRecipeModal(recipeId);
            });
        });
    }
    
    createRecipeCard(recipe) {
        const tags = recipe.dietary_tags || [];
        const rating = recipe.rating || 0;
        const reviewCount = recipe.review_count || 0;
        
        return `
            <div class="recipe-card" data-recipe-id="${recipe.id}">
                <div class="recipe-image">
                    <i class="fas fa-camera placeholder-icon"></i>
                    <div class="recipe-rating">
                        <i class="fas fa-star"></i>
                        ${rating.toFixed(1)} (${reviewCount})
                    </div>
                </div>
                <div class="recipe-content">
                    <h3 class="recipe-title">${recipe.title}</h3>
                    <div class="recipe-meta">
                        <span><i class="fas fa-clock"></i> ${recipe.cookTimeMinutes + recipe.prepTimeMinutes} min</span>
                        <span><i class="fas fa-users"></i> ${recipe.servingSize} servings</span>
                        <span><i class="fas fa-signal"></i> ${recipe.difficulty}</span>
                    </div>
                    <div class="recipe-tags">
                        ${tags.slice(0, 3).map(tag => `<span class="tag tag-${tag}">${tag}</span>`).join('')}
                    </div>
                    <div class="recipe-actions">
                        <button class="btn btn-outline btn-small">
                            <i class="fas fa-heart"></i>
                            Save
                        </button>
                        <button class="btn btn-primary btn-small">
                            <i class="fas fa-eye"></i>
                            View Recipe
                        </button>
                    </div>
                </div>
            </div>
        `;
    }
    
    async loadAppStats() {
        try {
            // In a real app, these would come from API
            const stats = {
                totalRecipes: 1247,
                mealPlansCreated: 3892,
                usersHelped: 12567
            };
            
            // Animate counters
            this.animateCounter('total-recipes', stats.totalRecipes);
            this.animateCounter('meal-plans-created', stats.mealPlansCreated);
            this.animateCounter('users-helped', stats.usersHelped);
            
        } catch (error) {
            console.error('Error loading app stats:', error);
        }
    }
    
    animateCounter(elementId, targetValue) {
        const element = document.getElementById(elementId);
        if (!element) return;
        
        const duration = 2000;
        const steps = 60;
        const stepValue = targetValue / steps;
        const stepDuration = duration / steps;
        
        let currentValue = 0;
        const timer = setInterval(() => {
            currentValue += stepValue;
            if (currentValue >= targetValue) {
                currentValue = targetValue;
                clearInterval(timer);
            }
            element.textContent = Math.floor(currentValue).toLocaleString();
        }, stepDuration);
    }
    
    async checkUserSession() {
        // Check for existing user session
        const userId = localStorage.getItem('userId');
        if (userId) {
            try {
                const response = await fetch(`${this.apiBase}/users/${userId}`);
                if (response.ok) {
                    const data = await response.json();
                    this.currentUser = data.user;
                    this.updateUIForUser();
                }
            } catch (error) {
                console.error('Error checking user session:', error);
                localStorage.removeItem('userId');
            }
        }
    }
    
    updateUIForUser() {
        if (this.currentUser) {
            // Update user profile button
            const profileBtn = document.getElementById('user-profile-btn');
            if (profileBtn) {
                profileBtn.innerHTML = `<i class="fas fa-user"></i> ${this.currentUser.username}`;
            }
        }
    }
    
    initializeComponents() {
        // Initialize specialized components
        try {
            this.yourFridge.initialize();
            console.log('Your Fridge initialized');
        } catch (error) {
            console.error('Error initializing Your Fridge:', error);
        }
        
        try {
            this.recipeGenerator.initialize();
            console.log('Recipe Generator initialized');
        } catch (error) {
            console.error('Error initializing Recipe Generator:', error);
        }
        
        try {
            this.mealPlanner.initialize();
            console.log('Meal Planner initialized');
        } catch (error) {
            console.error('Error initializing Meal Planner:', error);
        }
        
        try {
            this.nutritionTracker.initialize();
            console.log('Nutrition Tracker initialized');
        } catch (error) {
            console.error('Error initializing Nutrition Tracker:', error);
        }
        
        try {
            this.groceryListManager.initialize();
            console.log('Grocery List Manager initialized');
        } catch (error) {
            console.error('Error initializing Grocery List Manager:', error);
        }
    }
    
    setCurrentDate() {
        // Set current date for date inputs
        const today = new Date().toISOString().split('T')[0];
        
        document.querySelectorAll('input[type="date"]').forEach(input => {
            if (!input.value) {
                input.value = today;
            }
        });
    }
    
    navigateToPage(pageName) {
        // Hide all pages
        document.querySelectorAll('.page').forEach(page => {
            page.classList.remove('active');
        });
        
        // Show target page
        const targetPage = document.getElementById(`${pageName}-page`);
        if (targetPage) {
            targetPage.classList.add('active');
            this.currentPage = pageName;
            
            // Update navigation
            document.querySelectorAll('.nav-link').forEach(link => {
                link.classList.remove('active');
                if (link.dataset.page === pageName) {
                    link.classList.add('active');
                }
            });
            
            // Initialize page-specific functionality
            this.initializePage(pageName);
        }
    }
    
    initializePage(pageName) {
        switch (pageName) {
            case 'recipe-generator':
                if (this.recipeGenerator) {
                    this.recipeGenerator.initialize();
                }
                break;
            case 'meal-planner':
                if (this.mealPlanner) {
                    this.mealPlanner.initialize();
                }
                break;
            case 'nutrition-tracker':
                if (this.nutritionTracker) {
                    this.nutritionTracker.initialize();
                }
                break;
            case 'grocery-list':
                if (this.groceryListManager) {
                    this.groceryListManager.initialize();
                }
                break;
        }
    }
    
    // Modal management
    openModal(modalId, content = null, onOpen = null) {
        const modal = typeof modalId === 'string' ? document.getElementById(modalId) : modalId;
        if (!modal) {
            console.warn(`Modal with id "${modalId}" not found.`);
            return null;
        }

        if (typeof content === 'string') {
            const target = modal.querySelector('[data-modal-body]') || modal.querySelector('.modal-body');
            if (target) {
                target.innerHTML = content;
            }
        }

        modal.classList.add('active');
        document.body.style.overflow = 'hidden';

        if (typeof onOpen === 'function') {
            onOpen(modal);
        }

        return modal;
    }
    
    closeModal(target = null) {
        let modal = target;

        if (typeof modal === 'string') {
            modal = document.getElementById(modal);
        } else if (!modal) {
            const activeModals = Array.from(document.querySelectorAll('.modal.active'));
            modal = activeModals.pop() || null;
        }

        if (!modal) {
            return;
        }

        modal.classList.remove('active');

        if (!document.querySelector('.modal.active')) {
            document.body.style.overflow = '';
        }
    }
    
    closeAllModals() {
        document.querySelectorAll('.modal.active').forEach(modal => {
            this.closeModal(modal);
        });
    }
    
    async openRecipeModal(recipeId) {
        try {
            this.showLoading();
            
            const response = await fetch(`${this.apiBase}/recipes/${recipeId}`);
            const data = await response.json();
            
            if (data.recipe) {
                this.renderRecipeModal(data.recipe);
                this.openModal('recipe-modal');
            } else {
                this.showToast('Recipe not found', 'error');
            }
        } catch (error) {
            console.error('Error loading recipe:', error);
            this.showToast('Failed to load recipe', 'error');
        } finally {
            this.hideLoading();
        }
    }
    
    renderRecipeModal(recipe) {
        const modal = document.getElementById('recipe-modal');
        const title = document.getElementById('recipe-modal-title');
        const body = document.getElementById('recipe-modal-body');
        
        if (title) {
            title.textContent = recipe.title;
        }
        
        if (body) {
            const tags = recipe.dietary_tags || [];
            const nutrition = recipe.nutrition || {};
            
            body.innerHTML = `
                <div class="recipe-modal-content">
                    <div class="recipe-header">
                        <div class="recipe-image">
                            <i class="fas fa-camera placeholder-icon"></i>
                        </div>
                        <div class="recipe-info">
                            <div class="recipe-meta">
                                <span><i class="fas fa-clock"></i> Prep: ${recipe.prepTimeMinutes} min</span>
                                <span><i class="fas fa-fire"></i> Cook: ${recipe.cookTimeMinutes} min</span>
                                <span><i class="fas fa-users"></i> Serves: ${recipe.servingSize}</span>
                                <span><i class="fas fa-signal"></i> ${recipe.difficulty}</span>
                            </div>
                            <div class="recipe-tags">
                                ${tags.map(tag => `<span class="tag tag-${tag}">${tag}</span>`).join('')}
                            </div>
                            <div class="recipe-rating">
                                <div class="stars">
                                    ${this.renderStars(recipe.rating || 0)}
                                </div>
                                <span>${(recipe.rating || 0).toFixed(1)} (${recipe.review_count || 0} reviews)</span>
                            </div>
                        </div>
                    </div>
                    
                    <div class="recipe-sections">
                        <div class="ingredients-section">
                            <h3>Ingredients</h3>
                            <ul class="ingredients-list">
                                ${recipe.ingredients ? recipe.ingredients.map(ing => `
                                    <li>
                                        <span class="amount">${ing.amount} ${ing.unit}</span>
                                        <span class="name">${ing.name}</span>
                                    </li>
                                `).join('') : '<li>No ingredients listed.</li>'}
                            </ul>
                        </div>
                        
                        <div class="instructions-section">
                            <h3>Instructions</h3>
                            <ol class="instructions-list">
                                ${recipe.instructions.split('\n').map(instruction => `
                                    <li>${instruction}</li>
                                `).join('')}
                            </ol>
                        </div>
                        
                        ${Object.keys(nutrition).length > 0 ? `
                            <div class="nutrition-section">
                                <h3>Nutrition (per serving)</h3>
                                <div class="nutrition-grid">
                                    <div class="nutrition-item">
                                        <span class="value">${nutrition.calories || 0}</span>
                                        <span class="label">Calories</span>
                                    </div>
                                    <div class="nutrition-item">
                                        <span class="value">${nutrition.protein || 0}g</span>
                                        <span class="label">Protein</span>
                                    </div>
                                    <div class="nutrition-item">
                                        <span class="value">${nutrition.carbs || 0}g</span>
                                        <span class="label">Carbs</span>
                                    </div>
                                    <div class="nutrition-item">
                                        <span class="value">${nutrition.fat || 0}g</span>
                                        <span class="label">Fat</span>
                                    </div>
                                </div>
                            </div>
                        ` : ''}
                    </div>
                    
                    <div class="recipe-actions">
                        <button class="btn btn-outline" onclick="app.saveRecipe('${recipe.id}')">
                            <i class="fas fa-heart"></i>
                            Save Recipe
                        </button>
                        <button class="btn btn-primary" onclick="app.addToMealPlan('${recipe.id}')">
                            <i class="fas fa-calendar-plus"></i>
                            Add to Meal Plan
                        </button>
                        <button class="btn btn-secondary" onclick="app.generateGroceryList(['${recipe.id}'])">
                            <i class="fas fa-shopping-cart"></i>
                            Add to Grocery List
                        </button>
                    </div>
                </div>
            `;
        }
    }
    
    renderStars(rating) {
        const fullStars = Math.floor(rating);
        const hasHalfStar = rating % 1 >= 0.5;
        const emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
        
        return `
            ${'<i class="fas fa-star"></i>'.repeat(fullStars)}
            ${hasHalfStar ? '<i class="fas fa-star-half-alt"></i>' : ''}
            ${'<i class="far fa-star"></i>'.repeat(emptyStars)}
        `;
    }
    
    openPreferencesModal() {
        // Load user preferences form
        const modalBody = document.querySelector('#preferences-modal .modal-body');
        if (modalBody) {
            modalBody.innerHTML = this.renderPreferencesForm();
            this.setupPreferencesForm();
        }
        this.openModal('preferences-modal');
    }
    
    renderPreferencesForm() {
        const user = this.currentUser || {};
        const dietaryPreferences = user.dietary_preferences || [];
        const allergies = user.allergies || [];
        const nutritionalGoals = user.nutritional_goals || {};
        
        return `
            <form id="preferences-form">
                <div class="form-section">
                    <h3>Dietary Preferences</h3>
                    <div class="preferences-grid">
                        ${['vegan', 'vegetarian', 'gluten-free', 'keto', 'dairy-free', 'low-sodium', 'mediterranean', 'paleo'].map(pref => `
                            <label class="preference-item">
                                <input type="checkbox" value="${pref}" ${dietaryPreferences.includes(pref) ? 'checked' : ''}>
                                <span class="checkmark"></span>
                                ${pref.charAt(0).toUpperCase() + pref.slice(1)}
                            </label>
                        `).join('')}
                    </div>
                </div>
                
                <div class="form-section">
                    <h3>Allergies & Restrictions</h3>
                    <div class="preferences-grid">
                        ${['nuts', 'dairy', 'eggs', 'soy', 'shellfish', 'fish', 'wheat', 'sesame'].map(allergy => `
                            <label class="preference-item">
                                <input type="checkbox" name="allergies" value="${allergy}" ${allergies.includes(allergy) ? 'checked' : ''}>
                                <span class="checkmark"></span>
                                ${allergy.charAt(0).toUpperCase() + allergy.slice(1)}
                            </label>
                        `).join('')}
                    </div>
                </div>
                
                <div class="form-section">
                    <h3>Nutritional Goals</h3>
                    <div class="form-row">
                        <div class="form-group">
                            <label for="goal-calories">Daily Calories</label>
                            <input type="number" id="goal-calories" value="${nutritionalGoals.calories || 2000}" min="1000" max="5000">
                        </div>
                        <div class="form-group">
                            <label for="goal-protein">Protein (g)</label>
                            <input type="number" id="goal-protein" value="${nutritionalGoals.protein || 150}" min="50" max="300">
                        </div>
                    </div>
                </div>
                
                <div class="form-actions">
                    <button type="button" class="btn btn-outline" onclick="app.closeModal(document.getElementById('preferences-modal'))">
                        Cancel
                    </button>
                    <button type="submit" class="btn btn-primary">
                        Save Preferences
                    </button>
                </div>
            </form>
        `;
    }
    
    setupPreferencesForm() {
        const form = document.getElementById('preferences-form');
        if (form) {
            form.addEventListener('submit', async (e) => {
                e.preventDefault();
                await this.saveUserPreferences(form);
            });
        }
    }
    
    async saveUserPreferences(form) {
        try {
            this.showLoading();
            
            const formData = new FormData(form);
            const preferences = {
                dietary_preferences: Array.from(form.querySelectorAll('input[type="checkbox"]:not([name="allergies"]):checked')).map(cb => cb.value),
                allergies: Array.from(form.querySelectorAll('input[name="allergies"]:checked')).map(cb => cb.value),
                nutritional_goals: {
                    calories: parseInt(form.querySelector('#goal-calories').value),
                    protein: parseInt(form.querySelector('#goal-protein').value)
                }
            };
            
            if (this.currentUser) {
                // Update existing user
                const response = await fetch(`${this.apiBase}/users/${this.currentUser.id}/preferences`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(preferences)
                });
                
                if (response.ok) {
                    this.showToast('Preferences saved successfully', 'success');
                    this.closeModal(document.getElementById('preferences-modal'));
                    
                    // Update current user data
                    Object.assign(this.currentUser, preferences);
                }
            } else {
                // Store preferences for later user creation
                localStorage.setItem('userPreferences', JSON.stringify(preferences));
                this.showToast('Preferences saved locally', 'success');
                this.closeModal(document.getElementById('preferences-modal'));
            }
            
        } catch (error) {
            console.error('Error saving preferences:', error);
            this.showToast('Failed to save preferences', 'error');
        } finally {
            this.hideLoading();
        }
    }
    
    openUserProfile() {
        if (this.currentUser) {
            // Show user profile/settings
            this.showToast('User profile feature coming soon!', 'info');
        } else {
            // Show login/register options
            this.showToast('Please set up your profile in preferences first', 'info');
            this.openPreferencesModal();
        }
    }
    
    // Utility methods
    showLoading() {
        const overlay = document.getElementById('loading-overlay');
        if (overlay) {
            overlay.classList.add('active');
        }
    }
    
    hideLoading() {
        const overlay = document.getElementById('loading-overlay');
        if (overlay) {
            overlay.classList.remove('active');
        }
    }
    
    showToast(message, type = 'info') {
        const container = document.getElementById('toast-container');
        if (!container) return;
        
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.innerHTML = `
            <div class="toast-content">
                <i class="fas fa-${this.getToastIcon(type)}"></i>
                <span>${message}</span>
            </div>
        `;
        
        container.appendChild(toast);
        
        // Auto remove after 5 seconds
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 5000);
        
        // Click to dismiss
        toast.addEventListener('click', () => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        });
    }
    
    getToastIcon(type) {
        const icons = {
            success: 'check-circle',
            error: 'exclamation-circle',
            warning: 'exclamation-triangle',
            info: 'info-circle'
        };
        return icons[type] || 'info-circle';
    }
    
    // Recipe actions
    async saveRecipe(recipeId) {
        try {
            if (!this.currentUser) {
                this.showToast('Please set up your profile first', 'warning');
                return;
            }
            
            const response = await fetch(`${this.apiBase}/users/${this.currentUser.id}/favorites/${recipeId}`, {
                method: 'POST'
            });
            
            if (response.ok) {
                this.showToast('Recipe saved to favorites!', 'success');
            } else {
                this.showToast('Failed to save recipe', 'error');
            }
        } catch (error) {
            console.error('Error saving recipe:', error);
            this.showToast('Failed to save recipe', 'error');
        }
    }
    
    addToMealPlan(recipeId) {
        this.showToast('Meal plan feature coming soon!', 'info');
        // TODO: Implement meal plan functionality
    }
    
    generateGroceryList(recipeIds) {
        this.showToast('Grocery list feature coming soon!', 'info');
        // TODO: Implement grocery list functionality
    }
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.app = new RecipeMealPlannerApp();
});