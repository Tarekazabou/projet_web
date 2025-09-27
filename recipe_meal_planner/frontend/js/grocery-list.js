// ===== GROCERY LIST COMPONENT =====
class GroceryListManager {
    constructor(app) {
        this.app = app;
        this.groceryLists = [];
        this.currentList = null;
        this.categories = [
            'Produce', 'Meat & Seafood', 'Dairy', 'Pantry', 'Frozen', 
            'Bakery', 'Beverages', 'Snacks', 'Other'
        ];
    }
    
    initialize() {
        this.setupEventListeners();
        this.loadGroceryLists();
    }
    
    setupEventListeners() {
        // Create new list button
        const createListBtn = document.getElementById('create-grocery-list');
        if (createListBtn) {
            createListBtn.addEventListener('click', () => {
                this.createNewGroceryList();
            });
        }
        
        // Generate from meal plan button
        const generateFromMealPlanBtn = document.getElementById('generate-from-meal-plan');
        if (generateFromMealPlanBtn) {
            generateFromMealPlanBtn.addEventListener('click', () => {
                this.generateFromMealPlan();
            });
        }
        
        // Add item input
        const addItemInput = document.getElementById('add-grocery-item');
        if (addItemInput) {
            addItemInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.addGroceryItem(e.target.value.trim());
                    e.target.value = '';
                }
            });
        }
        
        // Add item button
        const addItemBtn = document.getElementById('add-item-btn');
        if (addItemBtn) {
            addItemBtn.addEventListener('click', () => {
                const input = document.getElementById('add-grocery-item');
                if (input && input.value.trim()) {
                    this.addGroceryItem(input.value.trim());
                    input.value = '';
                }
            });
        }
        
        // Clear completed button
        const clearCompletedBtn = document.getElementById('clear-completed');
        if (clearCompletedBtn) {
            clearCompletedBtn.addEventListener('click', () => {
                this.clearCompletedItems();
            });
        }
        
        // Share list button
        const shareListBtn = document.getElementById('share-grocery-list');
        if (shareListBtn) {
            shareListBtn.addEventListener('click', () => {
                this.shareGroceryList();
            });
        }
        
        // Export list button
        const exportListBtn = document.getElementById('export-grocery-list');
        if (exportListBtn) {
            exportListBtn.addEventListener('click', () => {
                this.exportGroceryList();
            });
        }
        
        // Store integration buttons
        const instacartBtn = document.getElementById('order-instacart');
        const amazonBtn = document.getElementById('order-amazon');
        
        if (instacartBtn) {
            instacartBtn.addEventListener('click', () => {
                this.orderViaInstacart();
            });
        }
        
        if (amazonBtn) {
            amazonBtn.addEventListener('click', () => {
                this.orderViaAmazon();
            });
        }
    }
    
    async loadGroceryLists() {
        try {
            const response = await fetch(`${this.app.apiBase}/grocery-lists`);
            const data = await response.json();
            
            if (response.ok) {
                this.groceryLists = data.grocery_lists || [];
                
                // Load the most recent active list or create a new one
                const activeList = this.groceryLists.find(list => list.status === 'active');
                if (activeList) {
                    this.currentList = activeList;
                } else if (this.groceryLists.length > 0) {
                    this.currentList = this.groceryLists[0];
                } else {
                    await this.createNewGroceryList();
                    return;
                }
                
                this.renderGroceryList();
                this.renderListSelector();
            } else {
                throw new Error('Failed to load grocery lists');
            }
        } catch (error) {
            console.error('Error loading grocery lists:', error);
            // Create a default list
            await this.createNewGroceryList();
        }
    }
    
    async createNewGroceryList() {
        const listName = prompt('Enter a name for your grocery list:', `Grocery List ${new Date().toLocaleDateString()}`);
        if (!listName) return;
        
        try {
            const response = await fetch(`${this.app.apiBase}/grocery-lists`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    name: listName,
                    items: [],
                    status: 'active'
                })
            });
            
            const data = await response.json();
            
            if (response.ok) {
                this.currentList = data.grocery_list;
                this.groceryLists.unshift(this.currentList);
                this.renderGroceryList();
                this.renderListSelector();
                this.app.showToast('New grocery list created!', 'success');
            } else {
                throw new Error(data.error || 'Failed to create grocery list');
            }
        } catch (error) {
            console.error('Error creating grocery list:', error);
            // Create a default local list if API fails
            this.currentList = {
                _id: 'local-' + Date.now(),
                name: listName,
                items: [],
                status: 'active',
                created_at: new Date().toISOString()
            };
            this.groceryLists.unshift(this.currentList);
            this.renderGroceryList();
            this.renderListSelector();
        }
    }
    
    renderListSelector() {
        const listSelector = document.getElementById('grocery-list-selector');
        if (!listSelector) return;
        
        if (this.groceryLists.length <= 1) {
            listSelector.style.display = 'none';
            return;
        }
        
        listSelector.style.display = 'block';
        listSelector.innerHTML = `
            <select id="current-grocery-list" class="form-input">
                ${this.groceryLists.map(list => `
                    <option value="${list._id}" ${list._id === this.currentList._id ? 'selected' : ''}>
                        ${list.name} (${list.items.length} items)
                    </option>
                `).join('')}
            </select>
        `;
        
        const selector = document.getElementById('current-grocery-list');
        selector.addEventListener('change', (e) => {
            const selectedList = this.groceryLists.find(list => list._id === e.target.value);
            if (selectedList) {
                this.currentList = selectedList;
                this.renderGroceryList();
            }
        });
    }
    
    renderGroceryList() {
        if (!this.currentList) return;
        
        this.renderListHeader();
        this.renderGroceryItems();
        this.renderListStats();
    }
    
    renderListHeader() {
        const listHeader = document.getElementById('grocery-list-header');
        if (!listHeader) return;
        
        const completedCount = this.currentList.items.filter(item => item.completed).length;
        const totalCount = this.currentList.items.length;
        
        listHeader.innerHTML = `
            <div class="list-title">
                <h2>${this.currentList.name}</h2>
                <div class="list-progress">
                    ${completedCount} of ${totalCount} items completed
                </div>
            </div>
            <div class="list-actions">
                <button class="btn btn-outline btn-small" onclick="app.groceryListManager.renameList()">
                    <i class="fas fa-edit"></i>
                    Rename
                </button>
                <button class="btn btn-outline btn-small" onclick="app.groceryListManager.deleteList()">
                    <i class="fas fa-trash"></i>
                    Delete
                </button>
            </div>
        `;
    }
    
    renderGroceryItems() {
        const itemsContainer = document.getElementById('grocery-items');
        if (!itemsContainer) return;
        
        if (this.currentList.items.length === 0) {
            itemsContainer.innerHTML = `
                <div class="empty-grocery-list">
                    <i class="fas fa-shopping-cart empty-state-icon"></i>
                    <h3>Your grocery list is empty</h3>
                    <p>Add items manually or generate from your meal plan</p>
                    <button class="btn btn-primary" onclick="document.getElementById('add-grocery-item').focus()">
                        <i class="fas fa-plus"></i>
                        Add First Item
                    </button>
                </div>
            `;
            return;
        }
        
        // Group items by category
        const groupedItems = this.groupItemsByCategory();
        
        itemsContainer.innerHTML = Object.keys(groupedItems).map(category => {
            const items = groupedItems[category];
            if (items.length === 0) return '';
            
            return `
                <div class="grocery-category">
                    <div class="category-header">
                        <h3 class="category-name">
                            <i class="${this.getCategoryIcon(category)}"></i>
                            ${category}
                        </h3>
                        <div class="category-count">${items.length} items</div>
                    </div>
                    <div class="category-items">
                        ${items.map(item => this.createGroceryItemElement(item)).join('')}
                    </div>
                </div>
            `;
        }).join('');
        
        // Add drag and drop listeners
        this.setupDragAndDrop();
    }
    
    groupItemsByCategory() {
        const grouped = {};
        
        // Initialize categories
        this.categories.forEach(category => {
            grouped[category] = [];
        });
        
        // Group items
        this.currentList.items.forEach(item => {
            const category = item.category || 'Other';
            if (!grouped[category]) {
                grouped[category] = [];
            }
            grouped[category].push(item);
        });
        
        return grouped;
    }
    
    getCategoryIcon(category) {
        const icons = {
            'Produce': 'fas fa-apple-alt',
            'Meat & Seafood': 'fas fa-drumstick-bite',
            'Dairy': 'fas fa-cheese',
            'Pantry': 'fas fa-jar',
            'Frozen': 'fas fa-snowflake',
            'Bakery': 'fas fa-bread-slice',
            'Beverages': 'fas fa-wine-bottle',
            'Snacks': 'fas fa-cookie-bite',
            'Other': 'fas fa-box'
        };
        
        return icons[category] || 'fas fa-box';
    }
    
    createGroceryItemElement(item) {
        const isCompleted = item.completed || false;
        const priority = item.priority || 'normal';
        
        return `
            <div class="grocery-item ${isCompleted ? 'completed' : ''} priority-${priority}" 
                 data-item-id="${item._id || item.id}" 
                 draggable="true">
                <div class="item-checkbox">
                    <input type="checkbox" 
                           ${isCompleted ? 'checked' : ''} 
                           onchange="app.groceryListManager.toggleItemCompletion('${item._id || item.id}')">
                </div>
                <div class="item-content">
                    <div class="item-main">
                        <span class="item-name">${item.name}</span>
                        ${item.quantity ? `<span class="item-quantity">${item.quantity}</span>` : ''}
                        ${item.notes ? `<span class="item-notes">${item.notes}</span>` : ''}
                    </div>
                    ${item.estimated_price ? `
                        <div class="item-price">$${item.estimated_price.toFixed(2)}</div>
                    ` : ''}
                </div>
                <div class="item-actions">
                    ${priority === 'high' ? '<i class="fas fa-exclamation priority-indicator" title="High Priority"></i>' : ''}
                    <button class="btn btn-outline btn-tiny" onclick="app.groceryListManager.editItem('${item._id || item.id}')">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-outline btn-tiny" onclick="app.groceryListManager.deleteItem('${item._id || item.id}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
        `;
    }
    
    renderListStats() {
        const statsContainer = document.getElementById('grocery-list-stats');
        if (!statsContainer) return;
        
        const totalItems = this.currentList.items.length;
        const completedItems = this.currentList.items.filter(item => item.completed).length;
        const estimatedTotal = this.currentList.items.reduce((sum, item) => sum + (item.estimated_price || 0), 0);
        
        const completionPercentage = totalItems > 0 ? (completedItems / totalItems) * 100 : 0;
        
        statsContainer.innerHTML = `
            <div class="list-stats">
                <div class="stat-item">
                    <div class="stat-value">${totalItems}</div>
                    <div class="stat-label">Total Items</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">${completedItems}</div>
                    <div class="stat-label">Completed</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">${Math.round(completionPercentage)}%</div>
                    <div class="stat-label">Progress</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">$${estimatedTotal.toFixed(2)}</div>
                    <div class="stat-label">Est. Total</div>
                </div>
            </div>
            
            <div class="completion-progress">
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${completionPercentage}%"></div>
                </div>
            </div>
        `;
    }
    
    async addGroceryItem(itemName, category = null, quantity = null, priority = 'normal') {
        if (!itemName) return;
        
        const newItem = {
            _id: 'temp-' + Date.now(),
            name: itemName,
            category: category || this.categorizeItem(itemName),
            quantity: quantity,
            priority: priority,
            completed: false,
            notes: '',
            estimated_price: this.estimatePrice(itemName),
            added_at: new Date().toISOString()
        };
        
        // Add to current list
        this.currentList.items.push(newItem);
        this.renderGroceryList();
        
        // Save to backend
        try {
            await this.saveGroceryList();
        } catch (error) {
            console.error('Error saving grocery item:', error);
        }
    }
    
    categorizeItem(itemName) {
        const itemLower = itemName.toLowerCase();
        
        // Simple categorization based on keywords
        const categoryKeywords = {
            'Produce': ['apple', 'banana', 'orange', 'lettuce', 'tomato', 'onion', 'carrot', 'potato', 'spinach', 'broccoli', 'cucumber', 'bell pepper', 'avocado', 'lemon', 'lime'],
            'Meat & Seafood': ['chicken', 'beef', 'pork', 'fish', 'salmon', 'shrimp', 'turkey', 'ham', 'bacon', 'sausage'],
            'Dairy': ['milk', 'cheese', 'yogurt', 'butter', 'cream', 'eggs'],
            'Pantry': ['rice', 'pasta', 'flour', 'sugar', 'salt', 'pepper', 'oil', 'vinegar', 'sauce', 'spice', 'herb'],
            'Frozen': ['frozen', 'ice cream', 'frozen vegetables', 'frozen fruit'],
            'Bakery': ['bread', 'bagel', 'muffin', 'cake', 'cookie'],
            'Beverages': ['water', 'juice', 'soda', 'coffee', 'tea', 'wine', 'beer'],
            'Snacks': ['chips', 'crackers', 'nuts', 'popcorn', 'candy', 'chocolate']
        };
        
        for (const [category, keywords] of Object.entries(categoryKeywords)) {
            if (keywords.some(keyword => itemLower.includes(keyword))) {
                return category;
            }
        }
        
        return 'Other';
    }
    
    estimatePrice(itemName) {
        // Simple price estimation based on common items
        const priceGuides = {
            'apple': 1.50, 'banana': 1.00, 'bread': 2.50, 'milk': 3.00,
            'eggs': 2.50, 'chicken': 5.00, 'rice': 2.00, 'pasta': 1.50
        };
        
        const itemLower = itemName.toLowerCase();
        for (const [item, price] of Object.entries(priceGuides)) {
            if (itemLower.includes(item)) {
                return price;
            }
        }
        
        return 0; // No estimate
    }
    
    async toggleItemCompletion(itemId) {
        const item = this.currentList.items.find(item => (item._id || item.id) === itemId);
        if (item) {
            item.completed = !item.completed;
            item.completed_at = item.completed ? new Date().toISOString() : null;
            
            this.renderGroceryList();
            
            try {
                await this.saveGroceryList();
            } catch (error) {
                console.error('Error saving item completion:', error);
            }
        }
    }
    
    async editItem(itemId) {
        const item = this.currentList.items.find(item => (item._id || item.id) === itemId);
        if (!item) return;
        
        const modalContent = `
            <div class="edit-item-modal">
                <h3>Edit Grocery Item</h3>
                <form id="edit-item-form">
                    <div class="form-group">
                        <label>Item Name</label>
                        <input type="text" id="edit-item-name" class="form-input" value="${item.name}" required>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Category</label>
                            <select id="edit-item-category" class="form-input">
                                ${this.categories.map(cat => `
                                    <option value="${cat}" ${cat === item.category ? 'selected' : ''}>${cat}</option>
                                `).join('')}
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Priority</label>
                            <select id="edit-item-priority" class="form-input">
                                <option value="low" ${item.priority === 'low' ? 'selected' : ''}>Low</option>
                                <option value="normal" ${item.priority === 'normal' ? 'selected' : ''}>Normal</option>
                                <option value="high" ${item.priority === 'high' ? 'selected' : ''}>High</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Quantity</label>
                            <input type="text" id="edit-item-quantity" class="form-input" value="${item.quantity || ''}" placeholder="e.g., 2 lbs, 1 dozen">
                        </div>
                        <div class="form-group">
                            <label>Est. Price</label>
                            <input type="number" id="edit-item-price" class="form-input" value="${item.estimated_price || ''}" step="0.01" min="0">
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Notes</label>
                        <textarea id="edit-item-notes" class="form-input" rows="2" placeholder="Any additional notes...">${item.notes || ''}</textarea>
                    </div>
                    <div class="modal-actions">
                        <button type="button" class="btn btn-outline" onclick="app.closeModal()">Cancel</button>
                        <button type="submit" class="btn btn-primary">Save Changes</button>
                    </div>
                </form>
            </div>
        `;
        
        this.app.openModal('edit-item-modal', modalContent, () => {
            document.getElementById('edit-item-form').addEventListener('submit', (e) => {
                e.preventDefault();
                this.saveItemEdit(itemId);
            });
        });
    }
    
    async saveItemEdit(itemId) {
        const item = this.currentList.items.find(item => (item._id || item.id) === itemId);
        if (!item) return;
        
        // Update item properties
        item.name = document.getElementById('edit-item-name').value;
        item.category = document.getElementById('edit-item-category').value;
        item.priority = document.getElementById('edit-item-priority').value;
        item.quantity = document.getElementById('edit-item-quantity').value || null;
        item.estimated_price = parseFloat(document.getElementById('edit-item-price').value) || 0;
        item.notes = document.getElementById('edit-item-notes').value || '';
        
        this.app.closeModal();
        this.renderGroceryList();
        
        try {
            await this.saveGroceryList();
            this.app.showToast('Item updated successfully!', 'success');
        } catch (error) {
            console.error('Error saving item edit:', error);
            this.app.showToast('Failed to save changes', 'error');
        }
    }
    
    async deleteItem(itemId) {
        if (!confirm('Are you sure you want to delete this item?')) {
            return;
        }
        
        this.currentList.items = this.currentList.items.filter(item => (item._id || item.id) !== itemId);
        this.renderGroceryList();
        
        try {
            await this.saveGroceryList();
        } catch (error) {
            console.error('Error saving after item deletion:', error);
        }
    }
    
    async clearCompletedItems() {
        const completedCount = this.currentList.items.filter(item => item.completed).length;
        
        if (completedCount === 0) {
            this.app.showToast('No completed items to clear', 'info');
            return;
        }
        
        if (!confirm(`Clear ${completedCount} completed items?`)) {
            return;
        }
        
        this.currentList.items = this.currentList.items.filter(item => !item.completed);
        this.renderGroceryList();
        
        try {
            await this.saveGroceryList();
            this.app.showToast(`${completedCount} completed items cleared`, 'success');
        } catch (error) {
            console.error('Error clearing completed items:', error);
        }
    }
    
    async generateFromMealPlan() {
        const generateBtn = document.getElementById('generate-from-meal-plan');
        if (generateBtn) {
            generateBtn.disabled = true;
            generateBtn.innerHTML = `
                <i class="fas fa-spinner fa-spin"></i>
                Generating...
            `;
        }
        
        try {
            // Get current week meal plan
            const response = await fetch(`${this.app.apiBase}/grocery-lists/generate-from-meal-plan`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    list_id: this.currentList._id
                })
            });
            
            const data = await response.json();
            
            if (response.ok) {
                // Add new items to current list
                const newItems = data.items || [];
                newItems.forEach(item => {
                    // Check if item already exists
                    const exists = this.currentList.items.some(existing => 
                        existing.name.toLowerCase() === item.name.toLowerCase()
                    );
                    
                    if (!exists) {
                        this.currentList.items.push({
                            ...item,
                            _id: 'temp-' + Date.now() + Math.random(),
                            completed: false,
                            added_at: new Date().toISOString()
                        });
                    }
                });
                
                this.renderGroceryList();
                this.app.showToast(`${newItems.length} items added from meal plan!`, 'success');
                
                // Save the updated list
                await this.saveGroceryList();
            } else {
                throw new Error(data.error || 'Failed to generate from meal plan');
            }
            
        } catch (error) {
            console.error('Error generating from meal plan:', error);
            this.app.showToast('Failed to generate from meal plan. Please try again.', 'error');
        } finally {
            if (generateBtn) {
                generateBtn.disabled = false;
                generateBtn.innerHTML = `
                    <i class="fas fa-utensils"></i>
                    Generate from Meal Plan
                `;
            }
        }
    }
    
    async saveGroceryList() {
        if (!this.currentList._id.startsWith('temp-') && !this.currentList._id.startsWith('local-')) {
            // Update existing list
            const response = await fetch(`${this.app.apiBase}/grocery-lists/${this.currentList._id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(this.currentList)
            });
            
            if (response.ok) {
                const data = await response.json();
                this.currentList = data.grocery_list;
            }
        }
    }
    
    shareGroceryList() {
        const shareData = {
            title: this.currentList.name,
            text: this.generateShareText(),
            url: window.location.href
        };
        
        if (navigator.share) {
            navigator.share(shareData).catch(console.error);
        } else {
            // Fallback: copy to clipboard
            navigator.clipboard.writeText(shareData.text).then(() => {
                this.app.showToast('Grocery list copied to clipboard!', 'success');
            }).catch(() => {
                // Manual copy fallback
                const textArea = document.createElement('textarea');
                textArea.value = shareData.text;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
                this.app.showToast('Grocery list copied to clipboard!', 'success');
            });
        }
    }
    
    generateShareText() {
        const pendingItems = this.currentList.items.filter(item => !item.completed);
        
        let shareText = `${this.currentList.name}\n\n`;
        
        const groupedItems = {};
        pendingItems.forEach(item => {
            const category = item.category || 'Other';
            if (!groupedItems[category]) {
                groupedItems[category] = [];
            }
            groupedItems[category].push(item);
        });
        
        Object.keys(groupedItems).forEach(category => {
            shareText += `${category}:\n`;
            groupedItems[category].forEach(item => {
                shareText += `  • ${item.name}`;
                if (item.quantity) shareText += ` (${item.quantity})`;
                shareText += '\n';
            });
            shareText += '\n';
        });
        
        return shareText;
    }
    
    exportGroceryList() {
        const exportData = {
            list: this.currentList,
            exported_at: new Date().toISOString(),
            summary: {
                total_items: this.currentList.items.length,
                completed_items: this.currentList.items.filter(item => item.completed).length,
                estimated_total: this.currentList.items.reduce((sum, item) => sum + (item.estimated_price || 0), 0)
            }
        };
        
        // Create multiple format options
        const formats = {
            'json': () => JSON.stringify(exportData, null, 2),
            'text': () => this.generateShareText(),
            'csv': () => this.generateCSV()
        };
        
        const format = prompt('Export format? (json/text/csv)', 'text');
        if (!format || !formats[format]) {
            this.app.showToast('Invalid format selected', 'error');
            return;
        }
        
        const content = formats[format]();
        const mimeTypes = {
            'json': 'application/json',
            'text': 'text/plain',
            'csv': 'text/csv'
        };
        
        const blob = new Blob([content], { type: mimeTypes[format] });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${this.currentList.name.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.${format}`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        this.app.showToast('Grocery list exported successfully!', 'success');
    }
    
    generateCSV() {
        const headers = ['Item Name', 'Category', 'Quantity', 'Priority', 'Completed', 'Est. Price', 'Notes'];
        const rows = [headers];
        
        this.currentList.items.forEach(item => {
            rows.push([
                item.name,
                item.category || '',
                item.quantity || '',
                item.priority || 'normal',
                item.completed ? 'Yes' : 'No',
                item.estimated_price || 0,
                item.notes || ''
            ]);
        });
        
        return rows.map(row => 
            row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(',')
        ).join('\n');
    }
    
    async orderViaInstacart() {
        if (this.currentList.items.length === 0) {
            this.app.showToast('Your grocery list is empty', 'warning');
            return;
        }
        
        // For now, open Instacart website with search terms
        const searchTerms = this.currentList.items
            .filter(item => !item.completed)
            .map(item => item.name)
            .slice(0, 5) // Limit to first 5 items
            .join(' ');
        
        const instacartUrl = `https://www.instacart.com/store/search?search_terms=${encodeURIComponent(searchTerms)}`;
        window.open(instacartUrl, '_blank');
        
        this.app.showToast('Opening Instacart in new tab...', 'info');
    }
    
    async orderViaAmazon() {
        if (this.currentList.items.length === 0) {
            this.app.showToast('Your grocery list is empty', 'warning');
            return;
        }
        
        // For now, open Amazon Fresh with search terms
        const searchTerms = this.currentList.items
            .filter(item => !item.completed)
            .map(item => item.name)
            .slice(0, 5) // Limit to first 5 items
            .join(' ');
        
        const amazonUrl = `https://www.amazon.com/s?k=${encodeURIComponent(searchTerms)}&i=amazonfresh`;
        window.open(amazonUrl, '_blank');
        
        this.app.showToast('Opening Amazon Fresh in new tab...', 'info');
    }
    
    async renameList() {
        const newName = prompt('Enter new name for this list:', this.currentList.name);
        if (!newName || newName === this.currentList.name) {
            return;
        }
        
        this.currentList.name = newName;
        this.renderGroceryList();
        this.renderListSelector();
        
        try {
            await this.saveGroceryList();
            this.app.showToast('List renamed successfully!', 'success');
        } catch (error) {
            console.error('Error renaming list:', error);
        }
    }
    
    async deleteList() {
        if (this.groceryLists.length <= 1) {
            this.app.showToast('Cannot delete the last grocery list', 'warning');
            return;
        }
        
        if (!confirm(`Are you sure you want to delete "${this.currentList.name}"?`)) {
            return;
        }
        
        try {
            if (!this.currentList._id.startsWith('local-')) {
                await fetch(`${this.app.apiBase}/grocery-lists/${this.currentList._id}`, {
                    method: 'DELETE'
                });
            }
            
            // Remove from local array
            this.groceryLists = this.groceryLists.filter(list => list._id !== this.currentList._id);
            
            // Switch to another list
            this.currentList = this.groceryLists[0];
            this.renderGroceryList();
            this.renderListSelector();
            
            this.app.showToast('Grocery list deleted', 'success');
            
        } catch (error) {
            console.error('Error deleting list:', error);
            this.app.showToast('Failed to delete list', 'error');
        }
    }
    
    setupDragAndDrop() {
        const items = document.querySelectorAll('.grocery-item');
        
        items.forEach(item => {
            item.addEventListener('dragstart', (e) => {
                e.dataTransfer.setData('text/plain', item.dataset.itemId);
                item.classList.add('dragging');
            });
            
            item.addEventListener('dragend', () => {
                item.classList.remove('dragging');
            });
        });
        
        const categories = document.querySelectorAll('.grocery-category');
        categories.forEach(category => {
            category.addEventListener('dragover', (e) => {
                e.preventDefault();
                category.classList.add('drag-over');
            });
            
            category.addEventListener('dragleave', () => {
                category.classList.remove('drag-over');
            });
            
            category.addEventListener('drop', (e) => {
                e.preventDefault();
                category.classList.remove('drag-over');
                
                const itemId = e.dataTransfer.getData('text/plain');
                const newCategory = category.querySelector('.category-name').textContent.trim();
                
                this.moveItemToCategory(itemId, newCategory);
            });
        });
    }
    
    async moveItemToCategory(itemId, newCategory) {
        const item = this.currentList.items.find(item => (item._id || item.id) === itemId);
        if (item && item.category !== newCategory) {
            item.category = newCategory;
            this.renderGroceryList();
            
            try {
                await this.saveGroceryList();
            } catch (error) {
                console.error('Error saving category change:', error);
            }
        }
    }
}