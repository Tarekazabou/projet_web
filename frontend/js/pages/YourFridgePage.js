/**
 * Your Fridge Page Controller
 * Manages fridge inventory and ingredient tracking
 */

class YourFridgePage {
    constructor() {
        this.fridgeItems = [];
        this.filteredItems = [];
        this.initialized = false;
    }

    /**
     * Initialize the fridge page
     */
    async init() {
        if (this.initialized) return;

        console.log('Initializing Your Fridge Page...');
        
        this.setupEventListeners();
        await this.loadFridgeItems();
        
        this.initialized = true;
    }

    setupEventListeners() {
        // Add ingredient button
        const addBtn = document.getElementById('add-ingredient-btn');
        if (addBtn) {
            addBtn.addEventListener('click', () => this.openAddIngredientModal());
        }

        // Seed demo items
        const seedBtn = document.getElementById('seed-demo-items-btn');
        if (seedBtn) {
            seedBtn.addEventListener('click', () => this.seedDemoItems());
        }

        // Bulk add
        const bulkBtn = document.getElementById('bulk-add-btn');
        if (bulkBtn) {
            bulkBtn.addEventListener('click', () => this.openBulkAddModal());
        }

        // Suggest recipes
        const suggestBtn = document.getElementById('suggest-recipes-btn');
        if (suggestBtn) {
            suggestBtn.addEventListener('click', () => this.suggestRecipes());
        }

        // Search and filters
        const searchInput = document.getElementById('fridge-search');
        if (searchInput) {
            searchInput.addEventListener('input', () => this.filterItems());
        }

        const categoryFilter = document.getElementById('category-filter');
        if (categoryFilter) {
            categoryFilter.addEventListener('change', () => this.filterItems());
        }

        const freshnessFilter = document.getElementById('freshness-filter');
        if (freshnessFilter) {
            freshnessFilter.addEventListener('change', () => this.filterItems());
        }

        const clearBtn = document.getElementById('clear-filters');
        if (clearBtn) {
            clearBtn.addEventListener('click', () => this.clearFilters());
        }
    }

    /**
     * Load fridge items from API
     */
    async loadFridgeItems() {
        try {
            window.loadingManager.show();

            const data = await window.apiClient.getFridgeItems();
            this.fridgeItems = data.items || [];
            this.filteredItems = [...this.fridgeItems];

            this.renderFridgeItems();
            this.updateStats();

        } catch (error) {
            console.error('Error loading fridge items:', error);
            window.toastManager.warning('Using demo items - could not load from server');
            this.seedDemoItems();
        } finally {
            window.loadingManager.hide();
        }
    }

    /**
     * Render fridge items
     */
    renderFridgeItems() {
        const container = document.getElementById('fridge-inventory');
        const emptyState = document.getElementById('empty-fridge');

        if (!container) return;

        if (this.filteredItems.length === 0) {
            container.innerHTML = '';
            if (emptyState) emptyState.classList.remove('hidden');
            return;
        }

        if (emptyState) emptyState.classList.add('hidden');

        container.innerHTML = this.filteredItems.map(item => this.createItemCard(item)).join('');

        // Add click listeners for delete buttons
        container.querySelectorAll('.delete-item-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const itemId = btn.dataset.itemId;
                this.deleteItem(itemId);
            });
        });
    }

    /**
     * Create item card HTML
     */
    createItemCard(item) {
        const freshness = window.dateUtils.getFreshnessStatus(item.expiryDate);
        const daysUntil = window.dateUtils.daysUntil(item.expiryDate);
        
        return `
            <div class="fridge-item ${freshness}" data-item-id="${item.id}">
                <div class="item-category-icon">
                    <i class="fas fa-${this.getCategoryIcon(item.category)}"></i>
                </div>
                <div class="item-details">
                    <h4 class="item-name">${item.name}</h4>
                    <p class="item-meta">
                        ${item.quantity} ${item.unit} • ${item.category}
                    </p>
                    <p class="item-expiry ${freshness}">
                        ${this.getExpiryText(daysUntil)}
                    </p>
                </div>
                <div class="item-actions">
                    <button class="btn btn-outline btn-small delete-item-btn" data-item-id="${item.id}">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
        `;
    }

    getCategoryIcon(category) {
        const icons = {
            produce: 'apple-alt',
            dairy: 'cheese',
            meat: 'drumstick-bite',
            pantry: 'jar',
            frozen: 'snowflake',
            beverages: 'wine-bottle',
            other: 'box'
        };
        return icons[category] || 'box';
    }

    getExpiryText(daysUntil) {
        if (daysUntil < 0) return 'Expired';
        if (daysUntil === 0) return 'Expires today';
        if (daysUntil === 1) return 'Expires tomorrow';
        if (daysUntil <= 3) return `Expires in ${daysUntil} days`;
        return `Expires in ${daysUntil} days`;
    }

    /**
     * Update statistics
     */
    updateStats() {
        const total = this.fridgeItems.length;
        const expiringSoon = this.fridgeItems.filter(item => 
            window.dateUtils.isExpiringSoon(item.expiryDate)
        ).length;
        const fresh = this.fridgeItems.filter(item => 
            window.dateUtils.getFreshnessStatus(item.expiryDate) === 'fresh'
        ).length;

        const totalEl = document.getElementById('total-ingredients');
        if (totalEl) totalEl.textContent = total;

        const expiringSoonEl = document.getElementById('expiring-soon');
        if (expiringSoonEl) expiringSoonEl.textContent = expiringSoon;

        const freshEl = document.getElementById('fresh-items');
        if (freshEl) freshEl.textContent = fresh;
    }

    /**
     * Filter items based on search and filters
     */
    filterItems() {
        const search = document.getElementById('fridge-search')?.value.toLowerCase() || '';
        const category = document.getElementById('category-filter')?.value || 'all';
        const freshness = document.getElementById('freshness-filter')?.value || 'all';

        this.filteredItems = this.fridgeItems.filter(item => {
            // Search filter
            if (search && !item.name.toLowerCase().includes(search)) {
                return false;
            }

            // Category filter
            if (category !== 'all' && item.category !== category) {
                return false;
            }

            // Freshness filter
            if (freshness !== 'all') {
                const itemFreshness = window.dateUtils.getFreshnessStatus(item.expiryDate);
                if (itemFreshness !== freshness) {
                    return false;
                }
            }

            return true;
        });

        this.renderFridgeItems();
    }

    /**
     * Clear all filters
     */
    clearFilters() {
        const searchInput = document.getElementById('fridge-search');
        if (searchInput) searchInput.value = '';

        const categoryFilter = document.getElementById('category-filter');
        if (categoryFilter) categoryFilter.value = 'all';

        const freshnessFilter = document.getElementById('freshness-filter');
        if (freshnessFilter) freshnessFilter.value = 'all';

        this.filterItems();
    }

    /**
     * Seed demo items
     */
    seedDemoItems() {
        this.fridgeItems = [
            {
                id: 'demo-1',
                name: 'Milk',
                category: 'dairy',
                quantity: 1,
                unit: 'liter',
                expiryDate: window.dateUtils.daysFromNow(7)
            },
            {
                id: 'demo-2',
                name: 'Chicken Breast',
                category: 'meat',
                quantity: 2,
                unit: 'pieces',
                expiryDate: window.dateUtils.daysFromNow(2)
            },
            {
                id: 'demo-3',
                name: 'Spinach',
                category: 'produce',
                quantity: 1,
                unit: 'bag',
                expiryDate: window.dateUtils.daysFromNow(3)
            },
            {
                id: 'demo-4',
                name: 'Rice',
                category: 'pantry',
                quantity: 1,
                unit: 'kg',
                expiryDate: window.dateUtils.daysFromNow(365)
            }
        ];

        this.filteredItems = [...this.fridgeItems];
        this.renderFridgeItems();
        this.updateStats();
        window.toastManager.success('Demo items added to your fridge');
    }

    /**
     * Delete an item
     */
    async deleteItem(itemId) {
        try {
            // For demo items, just remove from array
            if (itemId.startsWith('demo-')) {
                this.fridgeItems = this.fridgeItems.filter(item => item.id !== itemId);
                this.filterItems();
                this.updateStats();
                window.toastManager.success('Item removed');
                return;
            }

            // For real items, call API
            await window.apiClient.deleteFridgeItem(itemId);
            
            this.fridgeItems = this.fridgeItems.filter(item => item.id !== itemId);
            this.filterItems();
            this.updateStats();
            window.toastManager.success('Item removed');

        } catch (error) {
            console.error('Error deleting item:', error);
            window.toastManager.error('Failed to delete item');
        }
    }

    /**
     * Open add ingredient modal
     */
    openAddIngredientModal() {
        const modalContent = `
            <div class="add-ingredient-form">
                <h3><i class="fas fa-plus-circle"></i> Add Ingredient</h3>
                <form id="add-ingredient-form">
                    <div class="form-group">
                        <label for="ingredient-name">Ingredient Name *</label>
                        <input type="text" id="ingredient-name" name="name" class="form-input" 
                               placeholder="e.g., Chicken Breast" required>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="ingredient-quantity">Quantity *</label>
                            <input type="number" id="ingredient-quantity" name="quantity" 
                                   class="form-input" min="0" step="0.1" placeholder="1" required>
                        </div>
                        
                        <div class="form-group">
                            <label for="ingredient-unit">Unit *</label>
                            <select id="ingredient-unit" name="unit" class="form-input" required>
                                <option value="">Select unit</option>
                                <option value="pieces">Pieces</option>
                                <option value="kg">Kilogram (kg)</option>
                                <option value="g">Gram (g)</option>
                                <option value="liter">Liter</option>
                                <option value="ml">Milliliter (ml)</option>
                                <option value="cup">Cup</option>
                                <option value="tbsp">Tablespoon</option>
                                <option value="tsp">Teaspoon</option>
                                <option value="lb">Pound (lb)</option>
                                <option value="oz">Ounce (oz)</option>
                                <option value="bag">Bag</option>
                                <option value="box">Box</option>
                                <option value="can">Can</option>
                                <option value="jar">Jar</option>
                                <option value="bottle">Bottle</option>
                                <option value="bunch">Bunch</option>
                                <option value="clove">Clove</option>
                                <option value="bulb">Bulb</option>
                            </select>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label for="ingredient-category">Category</label>
                        <select id="ingredient-category" name="category" class="form-input">
                            <option value="produce">Produce</option>
                            <option value="dairy">Dairy</option>
                            <option value="meat">Meat & Seafood</option>
                            <option value="pantry">Pantry</option>
                            <option value="frozen">Frozen</option>
                            <option value="beverages">Beverages</option>
                            <option value="other">Other</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label for="ingredient-expiry">Expiration Date</label>
                        <input type="date" id="ingredient-expiry" name="expirationDate" 
                               class="form-input" min="${window.dateUtils.today()}">
                    </div>
                    
                    <div class="form-group">
                        <label for="ingredient-location">Location</label>
                        <input type="text" id="ingredient-location" name="location" 
                               class="form-input" placeholder="e.g., Main fridge" value="Main fridge">
                    </div>
                    
                    <div class="form-group">
                        <label for="ingredient-notes">Notes (optional)</label>
                        <textarea id="ingredient-notes" name="notes" class="form-input" 
                                  rows="2" placeholder="Any additional notes..."></textarea>
                    </div>
                    
                    <div class="form-actions">
                        <button type="button" class="btn btn-outline" id="cancel-add-btn">
                            Cancel
                        </button>
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-plus"></i> Add Ingredient
                        </button>
                    </div>
                </form>
            </div>
        `;

        window.modalManager.open('add-ingredient-modal', modalContent, () => {
            // Set up form submission
            const form = document.getElementById('add-ingredient-form');
            if (form) {
                form.addEventListener('submit', (e) => {
                    e.preventDefault();
                    this.handleAddIngredient(form);
                });
            }

            // Cancel button
            const cancelBtn = document.getElementById('cancel-add-btn');
            if (cancelBtn) {
                cancelBtn.addEventListener('click', () => {
                    window.modalManager.close();
                });
            }

            // Set default expiry date to 7 days from now
            const expiryInput = document.getElementById('ingredient-expiry');
            if (expiryInput && !expiryInput.value) {
                expiryInput.value = window.dateUtils.daysFromNow(7);
            }
        });
    }

    /**
     * Handle adding a new ingredient
     */
    async handleAddIngredient(form) {
        try {
            // Get form data
            const formData = new FormData(form);
            const data = {
                name: formData.get('name'),
                quantity: parseFloat(formData.get('quantity')),
                unit: formData.get('unit'),
                category: formData.get('category') || 'other',
                expirationDate: formData.get('expirationDate') || null,
                location: formData.get('location') || 'Main fridge',
                notes: formData.get('notes') || ''
            };

            // Validate
            if (!data.name || data.name.trim() === '') {
                window.toastManager.error('Please enter an ingredient name');
                return;
            }

            if (!data.quantity || data.quantity <= 0) {
                window.toastManager.error('Please enter a valid quantity');
                return;
            }

            if (!data.unit) {
                window.toastManager.error('Please select a unit');
                return;
            }

            window.loadingManager.show();

            // Add to backend
            const result = await window.apiClient.addFridgeItem(data);

            if (result.item) {
                // Add to local array
                this.fridgeItems.push(result.item);
                this.filterItems();
                this.updateStats();

                window.toastManager.success('Ingredient added successfully!');
                window.modalManager.close();
            }

        } catch (error) {
            console.error('Error adding ingredient:', error);
            window.toastManager.error('Failed to add ingredient. Please try again.');
        } finally {
            window.loadingManager.hide();
        }
    }

    /**
     * Open bulk add modal
     */
    openBulkAddModal() {
        window.toastManager.info('Bulk add feature coming soon!');
    }

    /**
     * Suggest recipes based on fridge items
     */
    async suggestRecipes() {
        try {
            // Don't check locally - let the backend validate against Firestore
            // The frontend's fridgeItems might not be synced with the database
            
            window.loadingManager.show();
            
            // Call the API to generate recipe suggestions
            // Backend will check Firestore directly for ingredients
            const result = await window.apiClient.suggestRecipesFromFridge({
                dietary_preferences: [],  // Can be extended with user preferences
                difficulty: 'medium',
                servings: 4
            });

            window.loadingManager.hide();
            
            if (result.recipe) {
                this.showRecipeModal(result.recipe, result.similar_recipes || []);
                window.toastManager.success('Recipe suggested successfully!');
            }

        } catch (error) {
            console.error('Error suggesting recipes:', error);
            window.loadingManager.hide();
            
            if (error.message.includes('No ingredients in fridge') || error.message.includes('Add some ingredients')) {
                window.toastManager.warning('No ingredients found in your fridge. Please add some ingredients first!');
            } else if (error.message.includes('AI services not available')) {
                window.toastManager.error('AI service not configured. Please check API key.');
            } else {
                window.toastManager.error('Failed to suggest recipes. Please try again.');
            }
        }
    }

    /**
     * Show suggested recipe in a modal
     */
    showRecipeModal(recipe, similarRecipes) {
        console.log('🔍 Recipe data received:', recipe); // Debug log
        
        // Handle different field name formats from API
        const cookTime = recipe.cookTimeMinutes || recipe.cooking_time || 0;
        const prepTime = recipe.prepTimeMinutes || recipe.prep_time || 0;
        const totalTime = cookTime + prepTime;
        const servings = recipe.servingSize || recipe.servings || 4;
        
        // Format ingredients - handle both string and object formats
        const formatIngredient = (ing) => {
            if (typeof ing === 'string') return ing;
            if (ing.name) {
                const parts = [];
                if (ing.quantity) parts.push(ing.quantity);
                if (ing.unit) parts.push(ing.unit);
                parts.push(ing.name);
                return parts.join(' ');
            }
            return JSON.stringify(ing);
        };
        
        const modalContent = `
            <div class="suggested-recipe-modal">
                <div class="recipe-header">
                    <h2>${recipe.title || 'Suggested Recipe'}</h2>
                    <span class="ai-badge">✨ AI Generated</span>
                </div>
                
                <div class="recipe-meta">
                    ${totalTime > 0 ? `<span><i class="fas fa-clock"></i> ${totalTime} min total</span>` : ''}
                    ${prepTime > 0 ? `<span><i class="fas fa-clock"></i> Prep: ${prepTime} min</span>` : ''}
                    ${cookTime > 0 ? `<span><i class="fas fa-fire"></i> Cook: ${cookTime} min</span>` : ''}
                    <span><i class="fas fa-users"></i> ${servings} servings</span>
                    ${recipe.difficulty ? `<span><i class="fas fa-signal"></i> ${recipe.difficulty}</span>` : ''}
                    ${recipe.cuisine ? `<span><i class="fas fa-globe"></i> ${recipe.cuisine}</span>` : ''}
                </div>

                ${recipe.description ? `
                <div class="recipe-section">
                    <h3><i class="fas fa-info-circle"></i> Description</h3>
                    <p>${recipe.description}</p>
                </div>
                ` : ''}

                <div class="recipe-section">
                    <h3><i class="fas fa-list"></i> Ingredients</h3>
                    <ul class="ingredients-list">
                        ${(recipe.ingredients || []).map(ing => `
                            <li>
                                <i class="fas fa-check-circle"></i>
                                ${formatIngredient(ing)}
                            </li>
                        `).join('')}
                    </ul>
                </div>

                <div class="recipe-section">
                    <h3><i class="fas fa-clipboard-list"></i> Instructions</h3>
                    <ol class="instructions-list">
                        ${(recipe.instructions || []).map(step => `
                            <li>${step}</li>
                        `).join('')}
                    </ol>
                </div>

                ${recipe.nutrition ? `
                    <div class="recipe-section">
                        <h3><i class="fas fa-chart-pie"></i> Nutrition (per serving)</h3>
                        <div class="nutrition-grid">
                            ${recipe.nutrition.calories ? `<div><strong>Calories:</strong> ${recipe.nutrition.calories}</div>` : ''}
                            ${recipe.nutrition.protein ? `<div><strong>Protein:</strong> ${recipe.nutrition.protein}g</div>` : ''}
                            ${recipe.nutrition.carbs ? `<div><strong>Carbs:</strong> ${recipe.nutrition.carbs}g</div>` : ''}
                            ${recipe.nutrition.fat ? `<div><strong>Fat:</strong> ${recipe.nutrition.fat}g</div>` : ''}
                            ${recipe.nutrition.fiber ? `<div><strong>Fiber:</strong> ${recipe.nutrition.fiber}g</div>` : ''}
                        </div>
                    </div>
                ` : ''}

                ${similarRecipes && similarRecipes.length > 0 ? `
                    <div class="recipe-section">
                        <h3>Based on these recipes:</h3>
                        <ul class="similar-recipes-list">
                            ${similarRecipes.map(r => `<li>${r.title || r.name || 'Recipe'}</li>`).join('')}
                        </ul>
                    </div>
                ` : ''}

                <div class="recipe-actions">
                    <button class="btn btn-outline" onclick="window.modalManager.close()">
                        <i class="fas fa-times"></i> Close
                    </button>
                    <button class="btn btn-primary" onclick="window.yourFridgePage.saveRecipe('${recipe.id || ''}')">
                        <i class="fas fa-bookmark"></i> Save Recipe
                    </button>
                </div>
            </div>
        `;

        // Use the existing recipe-modal
        window.modalManager.open('recipe-modal', modalContent);
    }

    /**
     * Save suggested recipe (placeholder for future implementation)
     */
    saveRecipe(recipeId) {
        if (recipeId) {
            window.toastManager.success('Recipe already saved!');
        } else {
            window.toastManager.info('Save to favorites feature coming soon!');
        }
        window.modalManager.close();
    }

    /**
     * Called when navigating to this page
     */
    onNavigate() {
        if (!this.initialized) {
            this.init();
        } else {
            this.loadFridgeItems();
        }
    }
}

// Register with router
window.addEventListener('DOMContentLoaded', () => {
    const fridgePage = new YourFridgePage();
    window.router.register('your-fridge', fridgePage);
    window.yourFridgePage = fridgePage; // Expose globally for onclick handlers
});
