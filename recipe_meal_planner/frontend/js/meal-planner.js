// ===== MEAL PLANNER COMPONENT =====
class MealPlanner {
    constructor(app) {
        this.app = app;
        this.currentWeek = this.getCurrentWeek();
        this.mealPlan = null;
        this.isDragging = false;
        this.draggedRecipe = null;
    }
    
    initialize() {
        this.setupEventListeners();
        this.renderWeekSelector();
        this.loadCurrentMealPlan();
    }
    
    setupEventListeners() {
        // Week navigation
        const prevWeekBtn = document.getElementById('prev-week');
        const nextWeekBtn = document.getElementById('next-week');
        
        if (prevWeekBtn) {
            prevWeekBtn.addEventListener('click', () => {
                this.navigateWeek(-1);
            });
        }
        
        if (nextWeekBtn) {
            nextWeekBtn.addEventListener('click', () => {
                this.navigateWeek(1);
            });
        }
        
        // Auto-generate button
        const autoGenerateBtn = document.getElementById('auto-generate-meal-plan');
        if (autoGenerateBtn) {
            autoGenerateBtn.addEventListener('click', () => {
                this.autoGenerateMealPlan();
            });
        }
        
        // Save meal plan button
        const saveMealPlanBtn = document.getElementById('save-meal-plan');
        if (saveMealPlanBtn) {
            saveMealPlanBtn.addEventListener('click', () => {
                this.saveMealPlan();
            });
        }
        
        // Export meal plan button
        const exportMealPlanBtn = document.getElementById('export-meal-plan');
        if (exportMealPlanBtn) {
            exportMealPlanBtn.addEventListener('click', () => {
                this.exportMealPlan();
            });
        }
    }
    
    getCurrentWeek() {
        const now = new Date();
        const startOfWeek = new Date(now);
        startOfWeek.setDate(now.getDate() - now.getDay()); // Start from Sunday
        startOfWeek.setHours(0, 0, 0, 0);
        
        return {
            start: startOfWeek,
            end: new Date(startOfWeek.getTime() + 6 * 24 * 60 * 60 * 1000)
        };
    }
    
    navigateWeek(direction) {
        const newStart = new Date(this.currentWeek.start);
        newStart.setDate(newStart.getDate() + (direction * 7));
        
        this.currentWeek = {
            start: newStart,
            end: new Date(newStart.getTime() + 6 * 24 * 60 * 60 * 1000)
        };
        
        this.renderWeekSelector();
        this.loadCurrentMealPlan();
    }
    
    renderWeekSelector() {
        const weekSelector = document.getElementById('current-week');
        if (!weekSelector) return;
        
        const startStr = this.currentWeek.start.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        const endStr = this.currentWeek.end.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
        
        weekSelector.textContent = `${startStr} - ${endStr}`;
        
        // Update navigation button states
        const prevBtn = document.getElementById('prev-week');
        const nextBtn = document.getElementById('next-week');
        const today = new Date();
        
        if (prevBtn) {
            // Allow going back up to 4 weeks
            const fourWeeksAgo = new Date(today.getTime() - 28 * 24 * 60 * 60 * 1000);
            prevBtn.disabled = this.currentWeek.start < fourWeeksAgo;
        }
        
        if (nextBtn) {
            // Allow planning up to 8 weeks ahead
            const eightWeeksAhead = new Date(today.getTime() + 56 * 24 * 60 * 60 * 1000);
            nextBtn.disabled = this.currentWeek.start > eightWeeksAhead;
        }
    }
    
    async loadCurrentMealPlan() {
        try {
            const startDate = this.currentWeek.start.toISOString().split('T')[0];
            const endDate = this.currentWeek.end.toISOString().split('T')[0];
            
            const response = await fetch(`${this.app.apiBase}/meal-plans?start_date=${startDate}&end_date=${endDate}`);
            const data = await response.json();
            
            if (response.ok && data.meal_plans && data.meal_plans.length > 0) {
                this.mealPlan = data.meal_plans[0];
            } else {
                this.mealPlan = this.createEmptyMealPlan();
            }
            
            this.renderMealPlan();
            this.updateMealPlanStats();
            
        } catch (error) {
            console.error('Error loading meal plan:', error);
            this.mealPlan = this.createEmptyMealPlan();
            this.renderMealPlan();
        }
    }
    
    createEmptyMealPlan() {
        const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
        const meals = {};
        
        days.forEach(day => {
            meals[day] = {
                breakfast: null,
                lunch: null,
                dinner: null,
                snacks: []
            };
        });
        
        return {
            _id: null,
            start_date: this.currentWeek.start.toISOString().split('T')[0],
            end_date: this.currentWeek.end.toISOString().split('T')[0],
            meals: meals,
            total_nutrition: {
                calories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                fiber: 0
            }
        };
    }
    
    renderMealPlan() {
        const mealPlanGrid = document.getElementById('meal-plan-grid');
        if (!mealPlanGrid) return;
        
        const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
        const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        
        mealPlanGrid.innerHTML = `
            <div class="meal-plan-header">
                <div class="time-slot-header">Meal</div>
                ${dayNames.map((dayName, index) => {
                    const date = new Date(this.currentWeek.start);
                    date.setDate(date.getDate() + index);
                    const dateStr = date.getDate();
                    const isToday = this.isToday(date);
                    
                    return `
                        <div class="day-header ${isToday ? 'today' : ''}">
                            <div class="day-name">${dayName}</div>
                            <div class="day-date">${dateStr}</div>
                        </div>
                    `;
                }).join('')}
            </div>
            
            ${this.renderMealRow('Breakfast', 'breakfast', days)}
            ${this.renderMealRow('Lunch', 'lunch', days)}
            ${this.renderMealRow('Dinner', 'dinner', days)}
            ${this.renderMealRow('Snacks', 'snacks', days)}
        `;
        
        this.setupMealSlotListeners();
    }
    
    renderMealRow(mealName, mealType, days) {
        return `
            <div class="meal-row">
                <div class="meal-time-label">${mealName}</div>
                ${days.map(day => {
                    const dayDate = new Date(this.currentWeek.start);
                    dayDate.setDate(dayDate.getDate() + days.indexOf(day));
                    const isToday = this.isToday(dayDate);
                    
                    return `
                        <div class="meal-slot ${isToday ? 'today' : ''}" 
                             data-day="${day}" 
                             data-meal="${mealType}"
                             ondrop="app.mealPlanner.handleDrop(event)"
                             ondragover="app.mealPlanner.handleDragOver(event)">
                            ${this.renderMealContent(this.mealPlan.meals[day][mealType], mealType)}
                        </div>
                    `;
                }).join('')}
            </div>
        `;
    }
    
    renderMealContent(mealData, mealType) {
        if (!mealData || (mealType === 'snacks' && mealData.length === 0)) {
            return `
                <div class="empty-meal-slot">
                    <i class="fas fa-plus-circle"></i>
                    <span>Add ${mealType === 'snacks' ? 'snack' : mealType}</span>
                </div>
            `;
        }
        
        if (mealType === 'snacks') {
            return mealData.map(snack => this.renderMealItem(snack)).join('');
        } else {
            return this.renderMealItem(mealData);
        }
    }
    
    renderMealItem(meal) {
        if (!meal) return '';
        
        const calories = meal.nutrition ? meal.nutrition.calories : 0;
        
        return `
            <div class="meal-item" data-recipe-id="${meal.recipe_id}">
                <div class="meal-item-header">
                    <h4 class="meal-title">${meal.recipe_title || meal.title}</h4>
                    <button class="remove-meal-btn" onclick="app.mealPlanner.removeMeal(event)">
                        <i class="fas fa-times"></i>
                    </button>
                </div>
                <div class="meal-meta">
                    <span class="meal-calories">${Math.round(calories)} cal</span>
                    <span class="meal-servings">${meal.servings || 1} serving${(meal.servings || 1) !== 1 ? 's' : ''}</span>
                </div>
                <div class="meal-actions">
                    <button class="btn btn-outline btn-tiny" onclick="app.openRecipeModal('${meal.recipe_id}')">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-outline btn-tiny" onclick="app.mealPlanner.editMealServings('${meal.recipe_id}', event)">
                        <i class="fas fa-edit"></i>
                    </button>
                </div>
            </div>
        `;
    }
    
    setupMealSlotListeners() {
        document.querySelectorAll('.meal-slot').forEach(slot => {
            if (slot.querySelector('.empty-meal-slot')) {
                slot.addEventListener('click', (e) => {
                    const day = slot.dataset.day;
                    const mealType = slot.dataset.meal;
                    this.openMealSelector(day, mealType);
                });
            }
        });
    }
    
    isToday(date) {
        const today = new Date();
        return date.toDateString() === today.toDateString();
    }
    
    async openMealSelector(day, mealType) {
        // Create meal selector modal content
        const modalContent = `
            <div class="meal-selector">
                <h3>Add ${mealType.charAt(0).toUpperCase() + mealType.slice(1)} for ${day.charAt(0).toUpperCase() + day.slice(1)}</h3>
                
                <div class="meal-selector-tabs">
                    <button class="tab-btn active" data-tab="recommended">Recommended</button>
                    <button class="tab-btn" data-tab="favorites">Favorites</button>
                    <button class="tab-btn" data-tab="search">Search</button>
                </div>
                
                <div class="tab-content" id="recommended-tab">
                    <div class="loading-spinner">
                        <i class="fas fa-spinner fa-spin"></i>
                        Finding recommended recipes...
                    </div>
                </div>
                
                <div class="tab-content hidden" id="favorites-tab">
                    <div class="loading-spinner">
                        <i class="fas fa-spinner fa-spin"></i>
                        Loading your favorites...
                    </div>
                </div>
                
                <div class="tab-content hidden" id="search-tab">
                    <div class="recipe-search">
                        <input type="text" id="meal-recipe-search" placeholder="Search for recipes..." class="form-input">
                        <div id="meal-search-results"></div>
                    </div>
                </div>
            </div>
        `;
        
        this.app.openModal('meal-selector-modal', modalContent, () => {
            this.setupMealSelectorListeners(day, mealType);
            this.loadRecommendedRecipes(mealType);
        });
    }
    
    setupMealSelectorListeners(day, mealType) {
        // Tab switching
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const tabName = btn.dataset.tab;
                this.switchMealSelectorTab(tabName, day, mealType);
            });
        });
        
        // Search functionality
        const searchInput = document.getElementById('meal-recipe-search');
        if (searchInput) {
            let searchTimeout;
            searchInput.addEventListener('input', (e) => {
                clearTimeout(searchTimeout);
                searchTimeout = setTimeout(() => {
                    this.searchRecipesForMeal(e.target.value, mealType);
                }, 500);
            });
        }
    }
    
    switchMealSelectorTab(tabName, day, mealType) {
        // Update tab buttons
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tab === tabName);
        });
        
        // Update tab content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.toggle('hidden', content.id !== `${tabName}-tab`);
        });
        
        // Load content if needed
        if (tabName === 'favorites' && !document.querySelector('#favorites-tab .recipe-grid')) {
            this.loadFavoriteRecipes(mealType);
        }
    }
    
    async loadRecommendedRecipes(mealType) {
        try {
            const response = await fetch(`${this.app.apiBase}/recipes/recommended?meal_type=${mealType}&limit=12`);
            const data = await response.json();
            
            if (response.ok && data.recipes) {
                this.renderMealSelectorRecipes(data.recipes, 'recommended-tab');
            } else {
                throw new Error('Failed to load recommendations');
            }
        } catch (error) {
            console.error('Error loading recommended recipes:', error);
            document.getElementById('recommended-tab').innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-exclamation-triangle"></i>
                    <p>Failed to load recommendations</p>
                </div>
            `;
        }
    }
    
    async loadFavoriteRecipes(mealType) {
        try {
            const response = await fetch(`${this.app.apiBase}/recipes/favorites?meal_type=${mealType}`);
            const data = await response.json();
            
            if (response.ok && data.recipes) {
                this.renderMealSelectorRecipes(data.recipes, 'favorites-tab');
            } else {
                throw new Error('Failed to load favorites');
            }
        } catch (error) {
            console.error('Error loading favorite recipes:', error);
            document.getElementById('favorites-tab').innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-heart"></i>
                    <p>No favorite recipes found</p>
                    <small>Save some recipes to see them here</small>
                </div>
            `;
        }
    }
    
    async searchRecipesForMeal(query, mealType) {
        const resultsContainer = document.getElementById('meal-search-results');
        
        if (!query.trim()) {
            resultsContainer.innerHTML = '';
            return;
        }
        
        resultsContainer.innerHTML = `
            <div class="loading-spinner">
                <i class="fas fa-spinner fa-spin"></i>
                Searching recipes...
            </div>
        `;
        
        try {
            const response = await fetch(`${this.app.apiBase}/recipes/search?q=${encodeURIComponent(query)}&meal_type=${mealType}`);
            const data = await response.json();
            
            if (response.ok && data.recipes) {
                this.renderMealSelectorRecipes(data.recipes, 'meal-search-results');
            } else {
                throw new Error('Search failed');
            }
        } catch (error) {
            console.error('Error searching recipes:', error);
            resultsContainer.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-search"></i>
                    <p>Search failed</p>
                </div>
            `;
        }
    }
    
    renderMealSelectorRecipes(recipes, containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;
        
        if (recipes.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-utensils"></i>
                    <p>No recipes found</p>
                </div>
            `;
            return;
        }
        
        container.innerHTML = `
            <div class="recipe-grid meal-selector-grid">
                ${recipes.map(recipe => this.createMealSelectorRecipeCard(recipe)).join('')}
            </div>
        `;
        
        // Add click listeners
        container.querySelectorAll('.recipe-card').forEach(card => {
            card.addEventListener('click', () => {
                const recipeId = card.dataset.recipeId;
                const recipeTitle = card.querySelector('.recipe-title').textContent;
                this.addRecipeToMeal(recipeId, recipeTitle);
            });
        });
    }
    
    createMealSelectorRecipeCard(recipe) {
        const calories = recipe.nutrition ? recipe.nutrition.calories : 0;
        const cookTime = (recipe.cooking_time || 0) + (recipe.prep_time || 0);
        
        return `
            <div class="recipe-card meal-selector-card" data-recipe-id="${recipe._id}">
                <div class="recipe-image">
                    <i class="fas fa-camera placeholder-icon"></i>
                </div>
                <div class="recipe-content">
                    <h4 class="recipe-title">${recipe.title}</h4>
                    <div class="recipe-meta">
                        <span><i class="fas fa-fire"></i> ${Math.round(calories)} cal</span>
                        <span><i class="fas fa-clock"></i> ${cookTime} min</span>
                    </div>
                    <button class="btn btn-primary btn-small select-recipe-btn">
                        <i class="fas fa-plus"></i>
                        Add to Meal Plan
                    </button>
                </div>
            </div>
        `;
    }
    
    addRecipeToMeal(recipeId, recipeTitle, day = null, mealType = null) {
        // If day and mealType are not provided, get them from the current modal context
        if (!day || !mealType) {
            // This should be set when opening the modal
            const modalData = this.getCurrentMealModalData();
            day = modalData.day;
            mealType = modalData.mealType;
        }
        
        // Create meal item
        const mealItem = {
            recipe_id: recipeId,
            recipe_title: recipeTitle,
            servings: 1,
            scheduled_for: new Date(this.currentWeek.start.getTime() + this.getDayOffset(day) * 24 * 60 * 60 * 1000).toISOString(),
            nutrition: null // Will be calculated when saved
        };
        
        // Add to meal plan
        if (mealType === 'snacks') {
            this.mealPlan.meals[day][mealType].push(mealItem);
        } else {
            this.mealPlan.meals[day][mealType] = mealItem;
        }
        
        // Re-render meal plan
        this.renderMealPlan();
        this.updateMealPlanStats();
        
        // Close modal
        this.app.closeModal();
        
        this.app.showToast(`Added ${recipeTitle} to ${day} ${mealType}!`, 'success');
    }
    
    getDayOffset(day) {
        const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
        return days.indexOf(day);
    }
    
    getCurrentMealModalData() {
        // This would need to be stored when opening the modal
        // For now, return default values
        return { day: 'monday', mealType: 'breakfast' };
    }
    
    removeMeal(event) {
        event.stopPropagation();
        
        const mealItem = event.target.closest('.meal-item');
        const mealSlot = mealItem.closest('.meal-slot');
        const day = mealSlot.dataset.day;
        const mealType = mealSlot.dataset.meal;
        const recipeId = mealItem.dataset.recipeId;
        
        if (mealType === 'snacks') {
            this.mealPlan.meals[day][mealType] = this.mealPlan.meals[day][mealType].filter(
                snack => snack.recipe_id !== recipeId
            );
        } else {
            this.mealPlan.meals[day][mealType] = null;
        }
        
        this.renderMealPlan();
        this.updateMealPlanStats();
        
        this.app.showToast('Meal removed from plan', 'success');
    }
    
    editMealServings(recipeId, event) {
        event.stopPropagation();
        
        const currentServings = this.findMealServings(recipeId);
        const newServings = prompt(`Enter number of servings:`, currentServings);
        
        if (newServings && !isNaN(newServings) && newServings > 0) {
            this.updateMealServings(recipeId, parseInt(newServings));
        }
    }
    
    findMealServings(recipeId) {
        for (const day in this.mealPlan.meals) {
            for (const mealType in this.mealPlan.meals[day]) {
                const meal = this.mealPlan.meals[day][mealType];
                
                if (mealType === 'snacks' && Array.isArray(meal)) {
                    const snack = meal.find(s => s.recipe_id === recipeId);
                    if (snack) return snack.servings || 1;
                } else if (meal && meal.recipe_id === recipeId) {
                    return meal.servings || 1;
                }
            }
        }
        return 1;
    }
    
    updateMealServings(recipeId, newServings) {
        for (const day in this.mealPlan.meals) {
            for (const mealType in this.mealPlan.meals[day]) {
                const meal = this.mealPlan.meals[day][mealType];
                
                if (mealType === 'snacks' && Array.isArray(meal)) {
                    const snack = meal.find(s => s.recipe_id === recipeId);
                    if (snack) {
                        snack.servings = newServings;
                        this.renderMealPlan();
                        this.updateMealPlanStats();
                        return;
                    }
                } else if (meal && meal.recipe_id === recipeId) {
                    meal.servings = newServings;
                    this.renderMealPlan();
                    this.updateMealPlanStats();
                    return;
                }
            }
        }
    }
    
    updateMealPlanStats() {
        // Calculate weekly nutrition totals
        let totalNutrition = {
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0
        };
        
        // This would need actual nutrition data from recipes
        // For now, show placeholder stats
        
        const statsContainer = document.getElementById('meal-plan-stats');
        if (statsContainer) {
            const plannedMeals = this.countPlannedMeals();
            
            statsContainer.innerHTML = `
                <div class="stat-item">
                    <div class="stat-value">${plannedMeals.total}</div>
                    <div class="stat-label">Total Meals</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">${plannedMeals.breakfast}</div>
                    <div class="stat-label">Breakfasts</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">${plannedMeals.lunch}</div>
                    <div class="stat-label">Lunches</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">${plannedMeals.dinner}</div>
                    <div class="stat-label">Dinners</div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">${plannedMeals.snacks}</div>
                    <div class="stat-label">Snacks</div>
                </div>
            `;
        }
    }
    
    countPlannedMeals() {
        let counts = {
            total: 0,
            breakfast: 0,
            lunch: 0,
            dinner: 0,
            snacks: 0
        };
        
        for (const day in this.mealPlan.meals) {
            const dayMeals = this.mealPlan.meals[day];
            
            if (dayMeals.breakfast) {
                counts.breakfast++;
                counts.total++;
            }
            
            if (dayMeals.lunch) {
                counts.lunch++;
                counts.total++;
            }
            
            if (dayMeals.dinner) {
                counts.dinner++;
                counts.total++;
            }
            
            counts.snacks += dayMeals.snacks.length;
            counts.total += dayMeals.snacks.length;
        }
        
        return counts;
    }
    
    async autoGenerateMealPlan() {
        if (!confirm('This will replace your current meal plan. Continue?')) {
            return;
        }
        
        const autoGenerateBtn = document.getElementById('auto-generate-meal-plan');
        if (autoGenerateBtn) {
            autoGenerateBtn.disabled = true;
            autoGenerateBtn.innerHTML = `
                <i class="fas fa-spinner fa-spin"></i>
                Generating...
            `;
        }
        
        try {
            const requestData = {
                start_date: this.currentWeek.start.toISOString().split('T')[0],
                end_date: this.currentWeek.end.toISOString().split('T')[0],
                preferences: this.app.userPreferences || {}
            };
            
            const response = await fetch(`${this.app.apiBase}/meal-plans/generate`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            });
            
            const data = await response.json();
            
            if (response.ok) {
                this.mealPlan = data.meal_plan;
                this.renderMealPlan();
                this.updateMealPlanStats();
                this.app.showToast('Meal plan generated successfully!', 'success');
            } else {
                throw new Error(data.error || 'Failed to generate meal plan');
            }
            
        } catch (error) {
            console.error('Error generating meal plan:', error);
            this.app.showToast('Failed to generate meal plan. Please try again.', 'error');
        } finally {
            if (autoGenerateBtn) {
                autoGenerateBtn.disabled = false;
                autoGenerateBtn.innerHTML = `
                    <i class="fas fa-magic"></i>
                    Auto-Generate Plan
                `;
            }
        }
    }
    
    async saveMealPlan() {
        const saveMealPlanBtn = document.getElementById('save-meal-plan');
        if (saveMealPlanBtn) {
            saveMealPlanBtn.disabled = true;
            saveMealPlanBtn.innerHTML = `
                <i class="fas fa-spinner fa-spin"></i>
                Saving...
            `;
        }
        
        try {
            const method = this.mealPlan._id ? 'PUT' : 'POST';
            const url = this.mealPlan._id ? 
                `${this.app.apiBase}/meal-plans/${this.mealPlan._id}` : 
                `${this.app.apiBase}/meal-plans`;
            
            const response = await fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(this.mealPlan)
            });
            
            const data = await response.json();
            
            if (response.ok) {
                this.mealPlan = data.meal_plan;
                this.app.showToast('Meal plan saved successfully!', 'success');
            } else {
                throw new Error(data.error || 'Failed to save meal plan');
            }
            
        } catch (error) {
            console.error('Error saving meal plan:', error);
            this.app.showToast('Failed to save meal plan. Please try again.', 'error');
        } finally {
            if (saveMealPlanBtn) {
                saveMealPlanBtn.disabled = false;
                saveMealPlanBtn.innerHTML = `
                    <i class="fas fa-save"></i>
                    Save Meal Plan
                `;
            }
        }
    }
    
    exportMealPlan() {
        const plannedMeals = this.countPlannedMeals();
        if (plannedMeals.total === 0) {
            this.app.showToast('No meals to export', 'warning');
            return;
        }
        
        // Create detailed export
        const startStr = this.currentWeek.start.toLocaleDateString();
        const endStr = this.currentWeek.end.toLocaleDateString();
        
        let exportText = `Meal Plan (${startStr} - ${endStr})\n`;
        exportText += `Generated on: ${new Date().toLocaleDateString()}\n\n`;
        
        const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
        const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        
        days.forEach((day, index) => {
            const dayMeals = this.mealPlan.meals[day];
            exportText += `${dayNames[index]}:\n`;
            
            if (dayMeals.breakfast) {
                exportText += `  Breakfast: ${dayMeals.breakfast.recipe_title} (${dayMeals.breakfast.servings} serving${dayMeals.breakfast.servings !== 1 ? 's' : ''})\n`;
            }
            
            if (dayMeals.lunch) {
                exportText += `  Lunch: ${dayMeals.lunch.recipe_title} (${dayMeals.lunch.servings} serving${dayMeals.lunch.servings !== 1 ? 's' : ''})\n`;
            }
            
            if (dayMeals.dinner) {
                exportText += `  Dinner: ${dayMeals.dinner.recipe_title} (${dayMeals.dinner.servings} serving${dayMeals.dinner.servings !== 1 ? 's' : ''})\n`;
            }
            
            if (dayMeals.snacks.length > 0) {
                exportText += `  Snacks: ${dayMeals.snacks.map(snack => `${snack.recipe_title} (${snack.servings})`).join(', ')}\n`;
            }
            
            exportText += '\n';
        });
        
        // Download as text file
        const blob = new Blob([exportText], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `meal-plan-${this.currentWeek.start.toISOString().split('T')[0]}.txt`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        this.app.showToast('Meal plan exported successfully!', 'success');
    }
    
    // Drag and drop functionality for recipes
    handleDragOver(event) {
        event.preventDefault();
        event.currentTarget.classList.add('drag-over');
    }
    
    handleDrop(event) {
        event.preventDefault();
        event.currentTarget.classList.remove('drag-over');
        
        const recipeData = JSON.parse(event.dataTransfer.getData('text/plain'));
        const day = event.currentTarget.dataset.day;
        const mealType = event.currentTarget.dataset.meal;
        
        this.addRecipeToMeal(recipeData.id, recipeData.title, day, mealType);
    }
}