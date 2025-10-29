// ===== YOUR FRIDGE COMPONENT =====
class YourFridge {
    constructor(app) {
        this.app = app;
        this.fridgeItems = [];
        this.filteredItems = [];
        this.categories = {
            'produce': { name: 'Produce', icon: 'fas fa-apple-alt', color: '#10b981' },
            'dairy': { name: 'Dairy', icon: 'fas fa-cheese', color: '#f59e0b' },
            'meat': { name: 'Meat & Seafood', icon: 'fas fa-drumstick-bite', color: '#ef4444' },
            'pantry': { name: 'Pantry', icon: 'fas fa-jar', color: '#8b5cf6' },
            'frozen': { name: 'Frozen', icon: 'fas fa-snowflake', color: '#06b6d4' },
            'beverages': { name: 'Beverages', icon: 'fas fa-wine-bottle', color: '#3b82f6' },
            'other': { name: 'Other', icon: 'fas fa-box', color: '#6b7280' }
        };
    }
    
    initialize() {
        this.setupEventListeners();
        this.loadFridgeItems();
    }
    
    setupEventListeners() {
        // Add ingredient button
        const addIngredientBtn = document.getElementById('add-ingredient-btn');
        if (addIngredientBtn) {
            addIngredientBtn.addEventListener('click', () => {
                this.openAddIngredientModal();
            });
        }
        
        // Scan receipt button
        const scanReceiptBtn = document.getElementById('scan-receipt-btn');
        if (scanReceiptBtn) {
            scanReceiptBtn.addEventListener('click', () => {
                this.openScanReceiptModal();
            });
        }
        
        // Bulk add button
        const bulkAddBtn = document.getElementById('bulk-add-btn');
        if (bulkAddBtn) {
            bulkAddBtn.addEventListener('click', () => {
                this.openBulkAddModal();
            });
        }
        
        // Suggest recipes button
        const suggestRecipesBtn = document.getElementById('suggest-recipes-btn');
        if (suggestRecipesBtn) {
            suggestRecipesBtn.addEventListener('click', () => {
                this.generateRecipeSuggestions();
            });
        }
        
        // Search functionality
        const fridgeSearch = document.getElementById('fridge-search');
        if (fridgeSearch) {
            fridgeSearch.addEventListener('input', (e) => {
                this.filterItems();
            });
        }
        
        // Filter controls
        const categoryFilter = document.getElementById('category-filter');
        const freshnessFilter = document.getElementById('freshness-filter');
        const clearFilters = document.getElementById('clear-filters');
        
        if (categoryFilter) {
            categoryFilter.addEventListener('change', () => {
                this.filterItems();
            });
        }
        
        if (freshnessFilter) {
            freshnessFilter.addEventListener('change', () => {
                this.filterItems();
            });
        }
        
        if (clearFilters) {
            clearFilters.addEventListener('click', () => {
                this.clearAllFilters();
            });
        }
    }
    
    async loadFridgeItems() {
        try {
            const response = await fetch(`${this.app.apiBase}/fridge/items`);
            const data = await response.json();
            
            if (response.ok) {
                this.fridgeItems = data || [];
            } else {
                // If no fridge data exists, create sample items for demo
                this.fridgeItems = this.createSampleItems();
            }
            
            this.filteredItems = [...this.fridgeItems];
            this.renderFridgeItems();
            this.updateStats();
            
        } catch (error) {
            console.error('Error loading fridge items:', error);
            // Use sample data for demo
            this.fridgeItems = this.createSampleItems();
            this.filteredItems = [...this.fridgeItems];
            this.renderFridgeItems();
            this.updateStats();
        }
    }
    
    createSampleItems() {
        const today = new Date();
        const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);
        const nextWeek = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000);
        const nextMonth = new Date(today.getTime() + 30 * 24 * 60 * 60 * 1000);
        
        return [
            {
                id: 'sample-1',
                name: 'Milk',
                category: 'dairy',
                quantity: 1,
                unit: 'liter',
                expiryDate: nextWeek.toISOString().split('T')[0],
                location: 'Main fridge',
                notes: 'Organic whole milk',
                addedDate: today.toISOString().split('T')[0]
            },
            {
                id: 'sample-2',
                name: 'Chicken Breast',
                category: 'meat',
                quantity: 2,
                unit: 'pieces',
                expiryDate: tomorrow.toISOString().split('T')[0],
                location: 'Freezer',
                notes: 'Free range',
                addedDate: today.toISOString().split('T')[0]
            },
            {
                id: 'sample-3',
                name: 'Spinach',
                category: 'produce',
                quantity: 1,
                unit: 'bag',
                expiryDate: nextWeek.toISOString().split('T')[0],
                location: 'Crisper drawer',
                notes: 'Baby spinach',
                addedDate: today.toISOString().split('T')[0]
            },
            {
                id: 'sample-4',
                name: 'Rice',
                category: 'pantry',
                quantity: 2,
                unit: 'kg',
                expiryDate: nextMonth.toISOString().split('T')[0],
                location: 'Pantry',
                notes: 'Basmati rice',
                addedDate: today.toISOString().split('T')[0]
            }
        ];
    }
    
    renderFridgeItems() {
        const fridgeInventory = document.getElementById('fridge-inventory');
        const emptyFridge = document.getElementById('empty-fridge');
        
        if (!fridgeInventory) return;
        
        if (this.filteredItems.length === 0) {
            fridgeInventory.style.display = 'none';
            if (emptyFridge) {
                emptyFridge.style.display = 'block';
            }
            return;
        }
        
        fridgeInventory.style.display = 'grid';
        if (emptyFridge) {
            emptyFridge.style.display = 'none';
        }
        
        // Group items by category
        const groupedItems = this.groupItemsByCategory();
        
        fridgeInventory.innerHTML = Object.keys(groupedItems).map(category => {
            const items = groupedItems[category];
            if (items.length === 0) return '';
            
            const categoryInfo = this.categories[category] || this.categories.other;
            
            return `
                <div class="category-section">
                    <div class="category-header">
                        <h3>
                            <i class="${categoryInfo.icon}" style="color: ${categoryInfo.color}"></i>
                            ${categoryInfo.name} (${items.length})
                        </h3>
                    </div>
                    <div class="category-items">
                        ${items.map(item => this.createIngredientItemElement(item)).join('')}
                    </div>
                </div>
            `;
        }).join('');
        
        // If no categories match, show individual items
        if (Object.keys(groupedItems).every(cat => groupedItems[cat].length === 0)) {
            fridgeInventory.innerHTML = this.filteredItems.map(item => 
                this.createIngredientItemElement(item)
            ).join('');
        }
    }
    
    groupItemsByCategory() {
        const grouped = {};
        
        // Initialize categories
        Object.keys(this.categories).forEach(category => {
            grouped[category] = [];
        });
        
        // Group items
        this.filteredItems.forEach(item => {
            const category = item.category || 'other';
            if (!grouped[category]) {
                grouped[category] = [];
            }
            grouped[category].push(item);
        });
        
        return grouped;
    }
    
    createIngredientItemElement(item) {
        const freshness = this.calculateFreshness(item.expiryDate);
        const categoryInfo = this.categories[item.category] || this.categories.other;
        
        return `
            <div class="ingredient-item ${freshness.class}" data-item-id="${item.id}">
                <div class="ingredient-header">
                    <div class="ingredient-info">
                        <h4 class="ingredient-name">${item.name}</h4>
                        <span class="ingredient-category" style="background-color: ${categoryInfo.color}">
                            <i class="${categoryInfo.icon}"></i>
                            ${categoryInfo.name}
                        </span>
                    </div>
                    <div class="ingredient-actions">
                        <button class="btn btn-outline btn-tiny" onclick="app.yourFridge.editIngredient('${item.id}')">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-outline btn-tiny" onclick="app.yourFridge.deleteIngredient('${item.id}')">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                
                <div class="ingredient-details">
                    <div class="detail-item">
                        <span class="detail-label">Quantity</span>
                        <div class="ingredient-quantity">
                            <div class="quantity-controls">
                                <button class="quantity-btn" onclick="app.yourFridge.updateQuantity('${item.id}', -1)">
                                    <i class="fas fa-minus"></i>
                                </button>
                                <span class="quantity-value">${item.quantity}</span>
                                <button class="quantity-btn" onclick="app.yourFridge.updateQuantity('${item.id}', 1)">
                                    <i class="fas fa-plus"></i>
                                </button>
                            </div>
                            <span class="detail-value">${item.unit}</span>
                        </div>
                    </div>
                    
                    <div class="detail-item">
                        <span class="detail-label">Expires</span>
                        <div class="expiry-date ${freshness.class}">
                            <i class="fas fa-calendar-alt"></i>
                            ${this.formatDate(item.expiryDate)}
                        </div>
                    </div>
                    
                    <div class="detail-item">
                        <span class="detail-label">Location</span>
                        <span class="detail-value">${item.location || 'Not specified'}</span>
                    </div>
                    
                    <div class="detail-item">
                        <span class="detail-label">Added</span>
                        <span class="detail-value">${this.formatDate(item.addedDate)}</span>
                    </div>
                </div>
                
                ${item.notes ? `
                    <div class="ingredient-notes">
                        <i class="fas fa-sticky-note"></i>
                        ${item.notes}
                    </div>
                ` : ''}
            </div>
        `;
    }
    
    calculateFreshness(expiryDate) {
        const today = new Date();
        const expiry = new Date(expiryDate);
        const diffTime = expiry - today;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays < 0) {
            return { class: 'expired', status: 'Expired' };
        } else if (diffDays <= 2) {
            return { class: 'expiring-soon', status: 'Expiring Soon' };
        } else {
            return { class: 'fresh', status: 'Fresh' };
        }
    }
    
    formatDate(dateString) {
        const date = new Date(dateString);
        const today = new Date();
        const diffTime = date - today;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        
        if (diffDays === 0) {
            return 'Today';
        } else if (diffDays === 1) {
            return 'Tomorrow';
        } else if (diffDays === -1) {
            return 'Yesterday';
        } else if (diffDays < 0) {
            return `${Math.abs(diffDays)} days ago`;
        } else if (diffDays <= 7) {
            return `${diffDays} days`;
        } else {
            return date.toLocaleDateString();
        }
    }
    
    updateStats() {
        const totalIngredients = document.getElementById('total-ingredients');
        const expiringSoon = document.getElementById('expiring-soon');
        const freshItems = document.getElementById('fresh-items');
        
        if (totalIngredients) {
            totalIngredients.textContent = this.fridgeItems.length;
        }
        
        if (expiringSoon) {
            const expiring = this.fridgeItems.filter(item => {
                const freshness = this.calculateFreshness(item.expiryDate);
                return freshness.class === 'expiring-soon' || freshness.class === 'expired';
            }).length;
            expiringSoon.textContent = expiring;
        }
        
        if (freshItems) {
            const fresh = this.fridgeItems.filter(item => {
                const freshness = this.calculateFreshness(item.expiryDate);
                return freshness.class === 'fresh';
            }).length;
            freshItems.textContent = fresh;
        }
    }
    
    filterItems() {
        const searchTerm = document.getElementById('fridge-search')?.value.toLowerCase() || '';
        const categoryFilter = document.getElementById('category-filter')?.value || 'all';
        const freshnessFilter = document.getElementById('freshness-filter')?.value || 'all';
        
        this.filteredItems = this.fridgeItems.filter(item => {
            // Search filter
            const matchesSearch = item.name.toLowerCase().includes(searchTerm) ||
                                item.category.toLowerCase().includes(searchTerm) ||
                                (item.notes && item.notes.toLowerCase().includes(searchTerm));
            
            // Category filter
            const matchesCategory = categoryFilter === 'all' || item.category === categoryFilter;
            
            // Freshness filter
            let matchesFreshness = true;
            if (freshnessFilter !== 'all') {
                const freshness = this.calculateFreshness(item.expiryDate);
                matchesFreshness = freshness.class === freshnessFilter;
            }
            
            return matchesSearch && matchesCategory && matchesFreshness;
        });
        
        this.renderFridgeItems();
    }
    
    clearAllFilters() {
        document.getElementById('fridge-search').value = '';
        document.getElementById('category-filter').value = 'all';
        document.getElementById('freshness-filter').value = 'all';
        this.filterItems();
    }
    
    openAddIngredientModal() {
        const modalContent = `
            <div class="ingredient-modal">
                <h3>Add Ingredient</h3>
                <form id="add-ingredient-form" class="ingredient-form">
                    <div class="form-group">
                        <label>Ingredient Name</label>
                        <input type="text" id="ingredient-name" class="form-input" required placeholder="e.g., Chicken Breast">
                    </div>
                    
                    <div class="form-group">
                        <label>Category</label>
                        <div class="category-icons">
                            ${Object.entries(this.categories).map(([key, cat]) => `
                                <div class="category-icon" data-category="${key}">
                                    <i class="${cat.icon}"></i>
                                    <span>${cat.name}</span>
                                </div>
                            `).join('')}
                        </div>
                        <input type="hidden" id="ingredient-category" required>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label>Quantity</label>
                            <input type="number" id="ingredient-quantity" class="form-input" min="0" step="0.1" required value="1">
                        </div>
                        <div class="form-group">
                            <label>Unit</label>
                            <select id="ingredient-unit" class="form-input" required>
                                <option value="pieces">pieces</option>
                                <option value="kg">kg</option>
                                <option value="g">grams</option>
                                <option value="liter">liter</option>
                                <option value="ml">ml</option>
                                <option value="cups">cups</option>
                                <option value="tbsp">tablespoons</option>
                                <option value="tsp">teaspoons</option>
                                <option value="bag">bag</option>
                                <option value="box">box</option>
                                <option value="can">can</option>
                                <option value="bottle">bottle</option>
                            </select>
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label>Expiration Date</label>
                            <input type="date" id="ingredient-expiry" class="form-input" required>
                        </div>
                        <div class="form-group">
                            <label>Location</label>
                            <select id="ingredient-location" class="form-input">
                                <option value="Main fridge">Main fridge</option>
                                <option value="Freezer">Freezer</option>
                                <option value="Pantry">Pantry</option>
                                <option value="Crisper drawer">Crisper drawer</option>
                                <option value="Door">Door</option>
                                <option value="Counter">Counter</option>
                                <option value="Other">Other</option>
                            </select>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label>Notes (Optional)</label>
                        <textarea id="ingredient-notes" class="form-input" rows="2" placeholder="Brand, special storage instructions, etc."></textarea>
                    </div>
                    
                    <div class="modal-actions">
                        <button type="button" class="btn btn-outline" onclick="app.closeModal()">Cancel</button>
                        <button type="submit" class="btn btn-primary">Add Ingredient</button>
                    </div>
                </form>
            </div>
        `;
        
        this.app.openModal('add-ingredient-modal', modalContent, () => {
            this.setupAddIngredientForm();
        });
    }
    
    setupAddIngredientForm() {
        // Category selection
        document.querySelectorAll('.category-icon').forEach(icon => {
            icon.addEventListener('click', () => {
                document.querySelectorAll('.category-icon').forEach(i => i.classList.remove('selected'));
                icon.classList.add('selected');
                document.getElementById('ingredient-category').value = icon.dataset.category;
            });
        });
        
        // Set default expiry date (7 days from now)
        const nextWeek = new Date();
        nextWeek.setDate(nextWeek.getDate() + 7);
        document.getElementById('ingredient-expiry').value = nextWeek.toISOString().split('T')[0];
        
        // Form submission
        document.getElementById('add-ingredient-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.addIngredient();
        });
    }
    
    async addIngredient() {
        const formData = {
            name: document.getElementById('ingredient-name').value,
            category: document.getElementById('ingredient-category').value,
            quantity: parseFloat(document.getElementById('ingredient-quantity').value),
            unit: document.getElementById('ingredient-unit').value,
            expiryDate: document.getElementById('ingredient-expiry').value,
            location: document.getElementById('ingredient-location').value,
            notes: document.getElementById('ingredient-notes').value,
            addedDate: new Date().toISOString().split('T')[0]
        };
        
        if (!formData.category) {
            this.app.showToast('Please select a category', 'warning');
            return;
        }
        
        try {
            const response = await fetch(`${this.app.apiBase}/fridge/items`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });
            
            const data = await response.json();
            
            if (response.ok) {
                this.fridgeItems.push(data);
                this.filterItems();
                this.updateStats();
                this.app.closeModal();
                this.app.showToast(`${formData.name} added to your fridge!`, 'success');
            } else {
                throw new Error(data.error || 'Failed to add ingredient');
            }
            
        } catch (error) {
            console.error('Error adding ingredient:', error);
            
            // Add locally for demo purposes
            const newItem = {
                id: 'temp-' + Date.now(),
                ...formData
            };
            
            this.fridgeItems.push(newItem);
            this.filterItems();
            this.updateStats();
            this.app.closeModal();
            this.app.showToast(`${formData.name} added to your fridge!`, 'success');
        }
    }
    
    async updateQuantity(itemId, change) {
        const item = this.fridgeItems.find(item => item.id === itemId);
        if (!item) return;
        
        const newQuantity = Math.max(0, item.quantity + change);
        
        if (newQuantity === 0) {
            if (confirm(`Remove ${item.name} from your fridge?`)) {
                this.deleteIngredient(itemId);
            }
            return;
        }
        
        item.quantity = newQuantity;
        this.renderFridgeItems();
        
        try {
            await fetch(`${this.app.apiBase}/fridge/items/${itemId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ quantity: newQuantity })
            });
        } catch (error) {
            console.error('Error updating quantity:', error);
        }
    }
    
    async deleteIngredient(itemId) {
        const item = this.fridgeItems.find(item => item.id === itemId);
        if (!item) return;
        
        if (!confirm(`Are you sure you want to remove ${item.name} from your fridge?`)) {
            return;
        }
        
        this.fridgeItems = this.fridgeItems.filter(item => item.id !== itemId);
        this.filterItems();
        this.updateStats();
        
        try {
            await fetch(`${this.app.apiBase}/fridge/items/${itemId}`, {
                method: 'DELETE'
            });
        } catch (error) {
            console.error('Error deleting ingredient:', error);
        }
        
        this.app.showToast(`${item.name} removed from your fridge`, 'success');
    }
    
    async generateRecipeSuggestions() {
        const suggestBtn = document.getElementById('suggest-recipes-btn');
        
        if (suggestBtn) {
            suggestBtn.disabled = true;
            suggestBtn.innerHTML = `
                <i class="fas fa-spinner fa-spin"></i>
                Finding Recipes...
            `;
        }
        
        try {
            // Get available ingredients
            const availableIngredients = this.fridgeItems
                .filter(item => {
                    const freshness = this.calculateFreshness(item.expiryDate);
                    return freshness.class !== 'expired';
                })
                .map(item => item.name);
            
            if (availableIngredients.length === 0) {
                this.app.showToast('Add some ingredients to get recipe suggestions!', 'warning');
                return;
            }
            
            // Call recipe search API
            const response = await fetch(`${this.app.apiBase}/recipes/search?q=${encodeURIComponent(availableIngredients.join(' '))}`);
            
            const data = await response.json();
            
            if (response.ok && data.recipes) {
                this.displayRecipeSuggestions(data.recipes);
            } else {
                throw new Error('Failed to get recipe suggestions');
            }
            
        } catch (error) {
            console.error('Error generating recipe suggestions:', error);
            this.app.showToast('Failed to generate recipe suggestions', 'error');
        } finally {
            if (suggestBtn) {
                suggestBtn.disabled = false;
                suggestBtn.innerHTML = `
                    <i class="fas fa-magic"></i>
                    Suggest Recipes
                `;
            }
        }
    }
    
    displayRecipeSuggestions(recipes) {
        const recipeSuggestionsSection = document.getElementById('recipe-suggestions-section');
        const suggestedRecipesGrid = document.getElementById('suggested-recipes-grid');
        
        if (!recipeSuggestionsSection || !suggestedRecipesGrid) return;
        
        if (recipes.length === 0) {
            recipeSuggestionsSection.style.display = 'none';
            this.app.showToast('No recipes found with your current ingredients', 'info');
            return;
        }
        
        recipeSuggestionsSection.style.display = 'block';
        
        suggestedRecipesGrid.innerHTML = recipes.slice(0, 6).map(recipe => 
            this.app.createRecipeCard ? this.app.createRecipeCard(recipe) : this.createSimpleRecipeCard(recipe)
        ).join('');
        
        // Add click listeners
        suggestedRecipesGrid.querySelectorAll('.recipe-card').forEach(card => {
            card.addEventListener('click', () => {
                const recipeId = card.dataset.recipeId;
                if (this.app.openRecipeModal) {
                    this.app.openRecipeModal(recipeId);
                }
            });
        });
        
        // Scroll to suggestions
        recipeSuggestionsSection.scrollIntoView({ behavior: 'smooth' });
    }
    
    createSimpleRecipeCard(recipe) {
        return `
            <div class="recipe-card" data-recipe-id="${recipe.id}">
                <div class="recipe-image">
                    <i class="fas fa-camera placeholder-icon"></i>
                </div>
                <div class="recipe-content">
                    <h3 class="recipe-title">${recipe.title}</h3>
                    <div class="recipe-meta">
                        <span><i class="fas fa-clock"></i> ${(recipe.cookTimeMinutes || 0) + (recipe.prepTimeMinutes || 0)} min</span>
                        <span><i class="fas fa-users"></i> ${recipe.servingSize} servings</span>
                    </div>
                    <div class="recipe-match">
                        <span class="match-indicator">
                            <i class="fas fa-check-circle"></i>
                            ${this.calculateIngredientMatch(recipe)}% match
                        </span>
                    </div>
                </div>
            </div>
        `;
    }
    
    calculateIngredientMatch(recipe) {
        const availableIngredients = this.fridgeItems.map(item => item.name.toLowerCase());
        const recipeIngredients = recipe.ingredients.map(ing => ing.name.toLowerCase());
        
        const matches = recipeIngredients.filter(ingredient =>
            availableIngredients.some(available =>
                available.includes(ingredient) || ingredient.includes(available)
            )
        ).length;
        
        return Math.round((matches / recipeIngredients.length) * 100);
    }
    
    openScanReceiptModal() {
        const modalContent = `
            <div class="scan-receipt-modal">
                <h3>Scan Receipt</h3>
                <div class="scan-container">
                    <div class="scan-placeholder">
                        <i class="fas fa-camera scan-icon"></i>
                        <h4>Camera Feature Coming Soon!</h4>
                        <p>This feature will allow you to scan grocery receipts and automatically add ingredients to your fridge.</p>
                        <p>For now, you can use the "Add Ingredient" or "Bulk Add" options.</p>
                    </div>
                    <div class="modal-actions">
                        <button type="button" class="btn btn-primary" onclick="app.closeModal()">Got it</button>
                    </div>
                </div>
            </div>
        `;
        
        this.app.openModal('scan-receipt-modal', modalContent);
    }
    
    openBulkAddModal() {
        const modalContent = `
            <div class="bulk-add-modal">
                <h3>Bulk Add Ingredients</h3>
                <form id="bulk-add-form" class="ingredient-form">
                    <div class="form-group">
                        <label>Ingredients List</label>
                        <textarea id="bulk-ingredients" class="form-input" rows="8" 
                                  placeholder="Enter ingredients, one per line:&#10;Milk - 1 liter&#10;Eggs - 12 pieces&#10;Chicken breast - 500g&#10;Tomatoes - 6 pieces"></textarea>
                        <small class="form-help">Format: Name - Quantity Unit (optional notes)</small>
                    </div>
                    
                    <div class="form-group">
                        <label>Default Category</label>
                        <select id="bulk-category" class="form-input">
                            <option value="">Auto-detect category</option>
                            ${Object.entries(this.categories).map(([key, cat]) => `
                                <option value="${key}">${cat.name}</option>
                            `).join('')}
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label>Default Expiry (days from now)</label>
                        <input type="number" id="bulk-expiry-days" class="form-input" value="7" min="1" max="365">
                    </div>
                    
                    <div class="modal-actions">
                        <button type="button" class="btn btn-outline" onclick="app.closeModal()">Cancel</button>
                        <button type="submit" class="btn btn-primary">Add All Ingredients</button>
                    </div>
                </form>
            </div>
        `;
        
        this.app.openModal('bulk-add-modal', modalContent, () => {
            document.getElementById('bulk-add-form').addEventListener('submit', (e) => {
                e.preventDefault();
                this.processBulkAdd();
            });
        });
    }
    
    async processBulkAdd() {
        const bulkText = document.getElementById('bulk-ingredients').value;
        const defaultCategory = document.getElementById('bulk-category').value;
        const expiryDays = parseInt(document.getElementById('bulk-expiry-days').value);
        
        if (!bulkText.trim()) {
            this.app.showToast('Please enter some ingredients', 'warning');
            return;
        }
        
        const lines = bulkText.trim().split('\n');
        const newItems = [];
        
        const expiryDate = new Date();
        expiryDate.setDate(expiryDate.getDate() + expiryDays);
        
        lines.forEach(line => {
            const parsed = this.parseBulkIngredientLine(line, defaultCategory, expiryDate);
            if (parsed) {
                newItems.push(parsed);
            }
        });
        
        if (newItems.length === 0) {
            this.app.showToast('No valid ingredients found', 'warning');
            return;
        }
        
        // Add all items
        newItems.forEach(item => {
            this.fridgeItems.push({
                id: 'temp-' + Date.now() + Math.random(),
                ...item
            });
        });
        
        this.filterItems();
        this.updateStats();
        this.app.closeModal();
        this.app.showToast(`Added ${newItems.length} ingredients to your fridge!`, 'success');
    }
    
    parseBulkIngredientLine(line, defaultCategory, defaultExpiry) {
        const trimmed = line.trim();
        if (!trimmed) return null;
        
        // Try to parse: "Name - Quantity Unit (Notes)"
        const parts = trimmed.split(' - ');
        const name = parts[0].trim();
        
        let quantity = 1;
        let unit = 'pieces';
        let category = defaultCategory;
        
        if (parts.length > 1) {
            // Parse quantity and unit
            const quantityPart = parts[1].trim();
            const quantityMatch = quantityPart.match(/^(\d+(?:\.\d+)?)\s*(.+)?$/);
            
            if (quantityMatch) {
                quantity = parseFloat(quantityMatch[1]);
                if (quantityMatch[2]) {
                    unit = quantityMatch[2].trim();
                }
            }
        }
        
        // Auto-detect category if not specified
        if (!category) {
            category = this.detectIngredientCategory(name);
        }
        
        return {
            name: name,
            category: category,
            quantity: quantity,
            unit: unit,
            expiryDate: defaultExpiry.toISOString().split('T')[0],
            location: 'Main fridge',
            notes: '',
            addedDate: new Date().toISOString().split('T')[0]
        };
    }
    
    detectIngredientCategory(name) {
        const nameLower = name.toLowerCase();
        
        const categoryKeywords = {
            'produce': ['apple', 'banana', 'tomato', 'lettuce', 'onion', 'carrot', 'potato', 'spinach', 'broccoli', 'cucumber', 'pepper', 'avocado', 'lemon', 'lime', 'orange'],
            'dairy': ['milk', 'cheese', 'yogurt', 'butter', 'cream', 'eggs'],
            'meat': ['chicken', 'beef', 'pork', 'fish', 'salmon', 'shrimp', 'turkey', 'ham', 'bacon', 'sausage'],
            'pantry': ['rice', 'pasta', 'flour', 'sugar', 'salt', 'pepper', 'oil', 'vinegar', 'sauce', 'spice'],
            'frozen': ['frozen'],
            'beverages': ['water', 'juice', 'soda', 'coffee', 'tea', 'wine', 'beer']
        };
        
        for (const [category, keywords] of Object.entries(categoryKeywords)) {
            if (keywords.some(keyword => nameLower.includes(keyword))) {
                return category;
            }
        }
        
        return 'other';
    }
}