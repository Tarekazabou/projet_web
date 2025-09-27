// ===== NUTRITION TRACKER COMPONENT =====
class NutritionTracker {
    constructor(app) {
        this.app = app;
        this.currentDate = new Date();
        this.nutritionData = null;
        this.nutritionGoals = null;
        this.charts = {};
    }
    
    initialize() {
        this.setupEventListeners();
        this.renderDateSelector();
        this.loadNutritionGoals();
        this.loadDailyNutrition();
    }
    
    setupEventListeners() {
        // Date navigation
        const prevDayBtn = document.getElementById('prev-day-nutrition');
        const nextDayBtn = document.getElementById('next-day-nutrition');
        
        if (prevDayBtn) {
            prevDayBtn.addEventListener('click', () => {
                this.navigateDay(-1);
            });
        }
        
        if (nextDayBtn) {
            nextDayBtn.addEventListener('click', () => {
                this.navigateDay(1);
            });
        }
        
        // Quick log buttons
        const quickLogBtn = document.getElementById('quick-log-meal');
        if (quickLogBtn) {
            quickLogBtn.addEventListener('click', () => {
                this.openQuickLogModal();
            });
        }
        
        // Set goals button
        const setGoalsBtn = document.getElementById('set-nutrition-goals');
        if (setGoalsBtn) {
            setGoalsBtn.addEventListener('click', () => {
                this.openNutritionGoalsModal();
            });
        }
        
        // Analyze recipe button
        const analyzeRecipeBtn = document.getElementById('analyze-recipe');
        if (analyzeRecipeBtn) {
            analyzeRecipeBtn.addEventListener('click', () => {
                this.openRecipeAnalysisModal();
            });
        }
        
        // Export nutrition data
        const exportNutritionBtn = document.getElementById('export-nutrition');
        if (exportNutritionBtn) {
            exportNutritionBtn.addEventListener('click', () => {
                this.exportNutritionData();
            });
        }
    }
    
    navigateDay(direction) {
        const newDate = new Date(this.currentDate);
        newDate.setDate(newDate.getDate() + direction);
        
        // Don't allow future dates
        const today = new Date();
        if (newDate > today) {
            return;
        }
        
        this.currentDate = newDate;
        this.renderDateSelector();
        this.loadDailyNutrition();
    }
    
    renderDateSelector() {
        const dateSelector = document.getElementById('nutrition-current-date');
        if (!dateSelector) return;
        
        const today = new Date();
        const isToday = this.currentDate.toDateString() === today.toDateString();
        const isYesterday = this.currentDate.toDateString() === new Date(today.getTime() - 24 * 60 * 60 * 1000).toDateString();
        
        let displayText;
        if (isToday) {
            displayText = 'Today';
        } else if (isYesterday) {
            displayText = 'Yesterday';
        } else {
            displayText = this.currentDate.toLocaleDateString('en-US', { 
                weekday: 'long', 
                month: 'short', 
                day: 'numeric' 
            });
        }
        
        dateSelector.textContent = displayText;
        
        // Update navigation buttons
        const nextBtn = document.getElementById('next-day-nutrition');
        if (nextBtn) {
            nextBtn.disabled = isToday;
        }
    }
    
    async loadNutritionGoals() {
        try {
            const response = await fetch(`${this.app.apiBase}/nutrition/goals`);
            const data = await response.json();
            
            if (response.ok) {
                this.nutritionGoals = data.goals;
            } else {
                // Set default goals
                this.nutritionGoals = {
                    calories: 2000,
                    protein: 150, // grams
                    carbs: 250,   // grams  
                    fat: 65,      // grams
                    fiber: 25,    // grams
                    sodium: 2300, // mg
                    sugar: 50     // grams
                };
            }
        } catch (error) {
            console.error('Error loading nutrition goals:', error);
            // Use default goals
            this.nutritionGoals = {
                calories: 2000,
                protein: 150,
                carbs: 250,
                fat: 65,
                fiber: 25,
                sodium: 2300,
                sugar: 50
            };
        }
    }
    
    async loadDailyNutrition() {
        try {
            const dateStr = this.currentDate.toISOString().split('T')[0];
            const response = await fetch(`${this.app.apiBase}/nutrition/daily/${dateStr}`);
            const data = await response.json();
            
            if (response.ok) {
                this.nutritionData = data.nutrition;
            } else {
                this.nutritionData = {
                    date: dateStr,
                    total_nutrition: {
                        calories: 0,
                        protein: 0,
                        carbs: 0,
                        fat: 0,
                        fiber: 0,
                        sodium: 0,
                        sugar: 0
                    },
                    meals: [],
                    water_intake: 0
                };
            }
            
            this.renderNutritionDashboard();
            this.renderMacroCharts();
            this.renderMealLog();
            
        } catch (error) {
            console.error('Error loading daily nutrition:', error);
            this.app.showToast('Failed to load nutrition data', 'error');
        }
    }
    
    renderNutritionDashboard() {
        const dashboardContainer = document.getElementById('nutrition-dashboard');
        if (!dashboardContainer) return;
        
        const nutrition = this.nutritionData.total_nutrition;
        const goals = this.nutritionGoals;
        
        dashboardContainer.innerHTML = `
            <div class="nutrition-overview">
                ${this.createNutritionCard('Calories', nutrition.calories, goals.calories, 'kcal', 'fas fa-fire')}
                ${this.createNutritionCard('Protein', nutrition.protein, goals.protein, 'g', 'fas fa-drumstick-bite')}
                ${this.createNutritionCard('Carbs', nutrition.carbs, goals.carbs, 'g', 'fas fa-bread-slice')}
                ${this.createNutritionCard('Fat', nutrition.fat, goals.fat, 'g', 'fas fa-cheese')}
            </div>
            
            <div class="nutrition-secondary">
                ${this.createNutritionCard('Fiber', nutrition.fiber, goals.fiber, 'g', 'fas fa-leaf', true)}
                ${this.createNutritionCard('Sodium', nutrition.sodium, goals.sodium, 'mg', 'fas fa-salt-shaker', true)}
                ${this.createNutritionCard('Sugar', nutrition.sugar, goals.sugar, 'g', 'fas fa-candy-cane', true)}
                ${this.createWaterIntakeCard()}
            </div>
        `;
        
        // Add click listeners for water intake
        this.setupWaterIntakeListeners();
    }
    
    createNutritionCard(name, current, goal, unit, icon, isSecondary = false) {
        const percentage = goal > 0 ? Math.min((current / goal) * 100, 100) : 0;
        const isOver = current > goal;
        const cardClass = isSecondary ? 'nutrition-card secondary' : 'nutrition-card';
        const statusClass = isOver ? 'over-goal' : percentage >= 90 ? 'near-goal' : 'on-track';
        
        return `
            <div class="${cardClass} ${statusClass}">
                <div class="nutrition-card-header">
                    <i class="${icon} nutrition-icon"></i>
                    <h4 class="nutrition-name">${name}</h4>
                </div>
                <div class="nutrition-values">
                    <div class="current-value">${Math.round(current)}<span class="unit">${unit}</span></div>
                    <div class="goal-value">/ ${goal}${unit}</div>
                </div>
                <div class="nutrition-progress">
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${percentage}%"></div>
                    </div>
                    <div class="progress-percentage">${Math.round(percentage)}%</div>
                </div>
                ${isOver ? `<div class="over-goal-warning">
                    <i class="fas fa-exclamation-triangle"></i>
                    ${Math.round(current - goal)}${unit} over goal
                </div>` : ''}
            </div>
        `;
    }
    
    createWaterIntakeCard() {
        const waterGoal = 8; // 8 glasses
        const currentWater = this.nutritionData.water_intake || 0;
        const percentage = (currentWater / waterGoal) * 100;
        
        return `
            <div class="nutrition-card water-card">
                <div class="nutrition-card-header">
                    <i class="fas fa-tint nutrition-icon"></i>
                    <h4 class="nutrition-name">Water</h4>
                </div>
                <div class="water-tracking">
                    <div class="water-glasses">
                        ${Array.from({length: 8}, (_, i) => `
                            <div class="water-glass ${i < currentWater ? 'filled' : ''}" data-glass="${i + 1}">
                                <i class="fas fa-glass-water"></i>
                            </div>
                        `).join('')}
                    </div>
                    <div class="water-count">${currentWater} / ${waterGoal} glasses</div>
                    <div class="water-actions">
                        <button class="btn btn-outline btn-small" id="decrease-water">
                            <i class="fas fa-minus"></i>
                        </button>
                        <button class="btn btn-primary btn-small" id="increase-water">
                            <i class="fas fa-plus"></i>
                        </button>
                    </div>
                </div>
            </div>
        `;
    }
    
    setupWaterIntakeListeners() {
        const increaseBtn = document.getElementById('increase-water');
        const decreaseBtn = document.getElementById('decrease-water');
        
        if (increaseBtn) {
            increaseBtn.addEventListener('click', () => {
                this.updateWaterIntake(1);
            });
        }
        
        if (decreaseBtn) {
            decreaseBtn.addEventListener('click', () => {
                this.updateWaterIntake(-1);
            });
        }
        
        // Glass click listeners
        document.querySelectorAll('.water-glass').forEach(glass => {
            glass.addEventListener('click', () => {
                const glassNumber = parseInt(glass.dataset.glass);
                this.setWaterIntake(glassNumber);
            });
        });
    }
    
    updateWaterIntake(change) {
        const newIntake = Math.max(0, Math.min(8, (this.nutritionData.water_intake || 0) + change));
        this.setWaterIntake(newIntake);
    }
    
    async setWaterIntake(glasses) {
        this.nutritionData.water_intake = glasses;
        this.renderNutritionDashboard();
        
        try {
            const dateStr = this.currentDate.toISOString().split('T')[0];
            await fetch(`${this.app.apiBase}/nutrition/water-intake`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    date: dateStr,
                    glasses: glasses
                })
            });
        } catch (error) {
            console.error('Error updating water intake:', error);
        }
    }
    
    renderMacroCharts() {
        this.renderCaloriesChart();
        this.renderMacroBreakdownChart();
    }
    
    renderCaloriesChart() {
        const chartContainer = document.getElementById('calories-chart');
        if (!chartContainer) return;
        
        const nutrition = this.nutritionData.total_nutrition;
        const goal = this.nutritionGoals.calories;
        const percentage = goal > 0 ? (nutrition.calories / goal) * 100 : 0;
        
        chartContainer.innerHTML = `
            <div class="chart-header">
                <h4>Daily Calories</h4>
                <div class="chart-value">
                    ${Math.round(nutrition.calories)} / ${goal} kcal
                </div>
            </div>
            <div class="circular-progress">
                <svg class="progress-ring" width="120" height="120">
                    <circle class="progress-ring-circle-bg" cx="60" cy="60" r="54"></circle>
                    <circle class="progress-ring-circle" cx="60" cy="60" r="54" 
                            style="stroke-dasharray: ${2 * Math.PI * 54}; stroke-dashoffset: ${2 * Math.PI * 54 * (1 - percentage / 100)}"></circle>
                </svg>
                <div class="progress-percentage">${Math.round(percentage)}%</div>
            </div>
        `;
    }
    
    renderMacroBreakdownChart() {
        const chartContainer = document.getElementById('macro-breakdown-chart');
        if (!chartContainer) return;
        
        const nutrition = this.nutritionData.total_nutrition;
        const totalCalories = nutrition.calories || 1; // Avoid division by zero
        
        // Calculate calories from each macro (protein: 4 cal/g, carbs: 4 cal/g, fat: 9 cal/g)
        const proteinCals = nutrition.protein * 4;
        const carbsCals = nutrition.carbs * 4;
        const fatCals = nutrition.fat * 9;
        const totalMacroCals = proteinCals + carbsCals + fatCals;
        
        // Calculate percentages
        const proteinPerc = totalMacroCals > 0 ? (proteinCals / totalMacroCals) * 100 : 0;
        const carbsPerc = totalMacroCals > 0 ? (carbsCals / totalMacroCals) * 100 : 0;
        const fatPerc = totalMacroCals > 0 ? (fatCals / totalMacroCals) * 100 : 0;
        
        chartContainer.innerHTML = `
            <div class="chart-header">
                <h4>Macro Breakdown</h4>
            </div>
            <div class="macro-bars">
                <div class="macro-bar">
                    <div class="macro-label">
                        <span class="macro-name">Protein</span>
                        <span class="macro-value">${Math.round(nutrition.protein)}g (${Math.round(proteinPerc)}%)</span>
                    </div>
                    <div class="macro-progress">
                        <div class="macro-fill protein" style="width: ${proteinPerc}%"></div>
                    </div>
                </div>
                
                <div class="macro-bar">
                    <div class="macro-label">
                        <span class="macro-name">Carbs</span>
                        <span class="macro-value">${Math.round(nutrition.carbs)}g (${Math.round(carbsPerc)}%)</span>
                    </div>
                    <div class="macro-progress">
                        <div class="macro-fill carbs" style="width: ${carbsPerc}%"></div>
                    </div>
                </div>
                
                <div class="macro-bar">
                    <div class="macro-label">
                        <span class="macro-name">Fat</span>
                        <span class="macro-value">${Math.round(nutrition.fat)}g (${Math.round(fatPerc)}%)</span>
                    </div>
                    <div class="macro-progress">
                        <div class="macro-fill fat" style="width: ${fatPerc}%"></div>
                    </div>
                </div>
            </div>
        `;
    }
    
    renderMealLog() {
        const mealLogContainer = document.getElementById('meal-log');
        if (!mealLogContainer) return;
        
        if (!this.nutritionData.meals || this.nutritionData.meals.length === 0) {
            mealLogContainer.innerHTML = `
                <div class="empty-meal-log">
                    <i class="fas fa-utensils empty-state-icon"></i>
                    <h3>No meals logged</h3>
                    <p>Start tracking your nutrition by logging meals</p>
                    <button class="btn btn-primary" onclick="app.nutritionTracker.openQuickLogModal()">
                        <i class="fas fa-plus"></i>
                        Log First Meal
                    </button>
                </div>
            `;
            return;
        }
        
        mealLogContainer.innerHTML = `
            <div class="meal-log-header">
                <h3>Today's Meals</h3>
                <button class="btn btn-primary btn-small" onclick="app.nutritionTracker.openQuickLogModal()">
                    <i class="fas fa-plus"></i>
                    Add Meal
                </button>
            </div>
            <div class="meal-entries">
                ${this.nutritionData.meals.map(meal => this.createMealLogEntry(meal)).join('')}
            </div>
        `;
    }
    
    createMealLogEntry(meal) {
        const time = new Date(meal.logged_at).toLocaleTimeString('en-US', { 
            hour: 'numeric', 
            minute: '2-digit' 
        });
        
        return `
            <div class="meal-entry" data-meal-id="${meal._id}">
                <div class="meal-entry-header">
                    <div class="meal-info">
                        <h4 class="meal-name">${meal.name}</h4>
                        <div class="meal-meta">
                            <span class="meal-time"><i class="fas fa-clock"></i> ${time}</span>
                            <span class="meal-type">${meal.meal_type}</span>
                        </div>
                    </div>
                    <div class="meal-actions">
                        <button class="btn btn-outline btn-tiny" onclick="app.nutritionTracker.editMeal('${meal._id}')">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-outline btn-tiny" onclick="app.nutritionTracker.deleteMeal('${meal._id}')">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                
                <div class="meal-nutrition">
                    <div class="nutrition-summary">
                        <span class="cal-badge">${Math.round(meal.nutrition.calories)} cal</span>
                        <span class="macro-summary">
                            P: ${Math.round(meal.nutrition.protein)}g | 
                            C: ${Math.round(meal.nutrition.carbs)}g | 
                            F: ${Math.round(meal.nutrition.fat)}g
                        </span>
                    </div>
                </div>
                
                ${meal.ingredients && meal.ingredients.length > 0 ? `
                    <div class="meal-ingredients">
                        <details>
                            <summary>View ingredients (${meal.ingredients.length})</summary>
                            <ul class="ingredient-list">
                                ${meal.ingredients.map(ing => `
                                    <li>${ing.amount} ${ing.unit} ${ing.name}</li>
                                `).join('')}
                            </ul>
                        </details>
                    </div>
                ` : ''}
            </div>
        `;
    }
    
    async openQuickLogModal() {
        const modalContent = `
            <div class="quick-log-modal">
                <h3>Quick Log Meal</h3>
                
                <div class="log-method-tabs">
                    <button class="tab-btn active" data-tab="search">Search Food</button>
                    <button class="tab-btn" data-tab="recipe">From Recipe</button>
                    <button class="tab-btn" data-tab="custom">Custom Entry</button>
                </div>
                
                <div class="tab-content" id="search-tab">
                    <div class="food-search">
                        <input type="text" id="food-search-input" placeholder="Search for food..." class="form-input">
                        <div id="food-search-results"></div>
                    </div>
                </div>
                
                <div class="tab-content hidden" id="recipe-tab">
                    <div class="recipe-search">
                        <input type="text" id="recipe-search-input" placeholder="Search your recipes..." class="form-input">
                        <div id="recipe-search-results"></div>
                    </div>
                </div>
                
                <div class="tab-content hidden" id="custom-tab">
                    <form id="custom-nutrition-form">
                        <div class="form-row">
                            <div class="form-group">
                                <label>Food Name</label>
                                <input type="text" id="custom-food-name" class="form-input" required>
                            </div>
                            <div class="form-group">
                                <label>Meal Type</label>
                                <select id="custom-meal-type" class="form-input">
                                    <option value="breakfast">Breakfast</option>
                                    <option value="lunch">Lunch</option>
                                    <option value="dinner">Dinner</option>
                                    <option value="snack">Snack</option>
                                </select>
                            </div>
                        </div>
                        
                        <div class="nutrition-inputs">
                            <div class="form-group">
                                <label>Calories</label>
                                <input type="number" id="custom-calories" class="form-input" min="0">
                            </div>
                            <div class="form-group">
                                <label>Protein (g)</label>
                                <input type="number" id="custom-protein" class="form-input" min="0" step="0.1">
                            </div>
                            <div class="form-group">
                                <label>Carbs (g)</label>
                                <input type="number" id="custom-carbs" class="form-input" min="0" step="0.1">
                            </div>
                            <div class="form-group">
                                <label>Fat (g)</label>
                                <input type="number" id="custom-fat" class="form-input" min="0" step="0.1">
                            </div>
                        </div>
                        
                        <div class="modal-actions">
                            <button type="button" class="btn btn-outline" onclick="app.closeModal()">Cancel</button>
                            <button type="submit" class="btn btn-primary">Log Meal</button>
                        </div>
                    </form>
                </div>
            </div>
        `;
        
        this.app.openModal('quick-log-modal', modalContent, () => {
            this.setupQuickLogListeners();
        });
    }
    
    setupQuickLogListeners() {
        // Tab switching
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const tabName = btn.dataset.tab;
                this.switchQuickLogTab(tabName);
            });
        });
        
        // Food search
        const foodSearchInput = document.getElementById('food-search-input');
        if (foodSearchInput) {
            let searchTimeout;
            foodSearchInput.addEventListener('input', (e) => {
                clearTimeout(searchTimeout);
                searchTimeout = setTimeout(() => {
                    this.searchFoodDatabase(e.target.value);
                }, 500);
            });
        }
        
        // Recipe search
        const recipeSearchInput = document.getElementById('recipe-search-input');
        if (recipeSearchInput) {
            let searchTimeout;
            recipeSearchInput.addEventListener('input', (e) => {
                clearTimeout(searchTimeout);
                searchTimeout = setTimeout(() => {
                    this.searchUserRecipes(e.target.value);
                }, 500);
            });
        }
        
        // Custom form
        const customForm = document.getElementById('custom-nutrition-form');
        if (customForm) {
            customForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.submitCustomNutritionEntry();
            });
        }
    }
    
    switchQuickLogTab(tabName) {
        // Update tab buttons
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tab === tabName);
        });
        
        // Update tab content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.toggle('hidden', content.id !== `${tabName}-tab`);
        });
    }
    
    async searchFoodDatabase(query) {
        const resultsContainer = document.getElementById('food-search-results');
        if (!query.trim()) {
            resultsContainer.innerHTML = '';
            return;
        }
        
        resultsContainer.innerHTML = `
            <div class="loading-spinner">
                <i class="fas fa-spinner fa-spin"></i>
                Searching food database...
            </div>
        `;
        
        try {
            const response = await fetch(`${this.app.apiBase}/nutrition/search-food?query=${encodeURIComponent(query)}`);
            const data = await response.json();
            
            if (response.ok && data.foods) {
                this.renderFoodSearchResults(data.foods);
            } else {
                throw new Error('Search failed');
            }
        } catch (error) {
            console.error('Error searching food database:', error);
            resultsContainer.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-search"></i>
                    <p>Search failed. Try a different term.</p>
                </div>
            `;
        }
    }
    
    renderFoodSearchResults(foods) {
        const resultsContainer = document.getElementById('food-search-results');
        
        if (foods.length === 0) {
            resultsContainer.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-search"></i>
                    <p>No foods found</p>
                </div>
            `;
            return;
        }
        
        resultsContainer.innerHTML = `
            <div class="food-results">
                ${foods.map(food => `
                    <div class="food-item" onclick="app.nutritionTracker.selectFood('${food.id}', '${food.name}', ${JSON.stringify(food.nutrition).replace(/"/g, '&quot;')})">
                        <div class="food-info">
                            <h4 class="food-name">${food.name}</h4>
                            <div class="food-nutrition">
                                ${Math.round(food.nutrition.calories)} cal per ${food.serving_size || '100g'}
                            </div>
                        </div>
                        <i class="fas fa-plus food-add-icon"></i>
                    </div>
                `).join('')}
            </div>
        `;
    }
    
    async searchUserRecipes(query) {
        const resultsContainer = document.getElementById('recipe-search-results');
        if (!query.trim()) {
            resultsContainer.innerHTML = '';
            return;
        }
        
        resultsContainer.innerHTML = `
            <div class="loading-spinner">
                <i class="fas fa-spinner fa-spin"></i>
                Searching your recipes...
            </div>
        `;
        
        try {
            const response = await fetch(`${this.app.apiBase}/recipes/search?q=${encodeURIComponent(query)}`);
            const data = await response.json();
            
            if (response.ok && data.recipes) {
                this.renderRecipeSearchResults(data.recipes);
            } else {
                throw new Error('Search failed');
            }
        } catch (error) {
            console.error('Error searching recipes:', error);
            resultsContainer.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-search"></i>
                    <p>Search failed. Try a different term.</p>
                </div>
            `;
        }
    }
    
    renderRecipeSearchResults(recipes) {
        const resultsContainer = document.getElementById('recipe-search-results');
        
        if (recipes.length === 0) {
            resultsContainer.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-search"></i>
                    <p>No recipes found</p>
                </div>
            `;
            return;
        }
        
        resultsContainer.innerHTML = `
            <div class="recipe-results">
                ${recipes.map(recipe => `
                    <div class="recipe-item" onclick="app.nutritionTracker.selectRecipe('${recipe._id}', '${recipe.title}', ${JSON.stringify(recipe.nutrition || {}).replace(/"/g, '&quot;')})">
                        <div class="recipe-info">
                            <h4 class="recipe-name">${recipe.title}</h4>
                            <div class="recipe-nutrition">
                                ${Math.round(recipe.nutrition?.calories || 0)} cal per serving
                            </div>
                        </div>
                        <i class="fas fa-plus recipe-add-icon"></i>
                    </div>
                `).join('')}
            </div>
        `;
    }
    
    selectFood(foodId, foodName, nutrition) {
        this.logMealEntry({
            name: foodName,
            meal_type: 'snack',
            nutrition: nutrition,
            source: 'food_database',
            source_id: foodId
        });
    }
    
    selectRecipe(recipeId, recipeName, nutrition) {
        this.logMealEntry({
            name: recipeName,
            meal_type: 'lunch',
            nutrition: nutrition,
            source: 'recipe',
            source_id: recipeId
        });
    }
    
    submitCustomNutritionEntry() {
        const formData = {
            name: document.getElementById('custom-food-name').value,
            meal_type: document.getElementById('custom-meal-type').value,
            nutrition: {
                calories: parseFloat(document.getElementById('custom-calories').value) || 0,
                protein: parseFloat(document.getElementById('custom-protein').value) || 0,
                carbs: parseFloat(document.getElementById('custom-carbs').value) || 0,
                fat: parseFloat(document.getElementById('custom-fat').value) || 0,
                fiber: 0,
                sodium: 0,
                sugar: 0
            },
            source: 'custom',
            ingredients: []
        };
        
        this.logMealEntry(formData);
    }
    
    async logMealEntry(mealData) {
        try {
            const requestData = {
                ...mealData,
                date: this.currentDate.toISOString().split('T')[0],
                logged_at: new Date().toISOString()
            };
            
            const response = await fetch(`${this.app.apiBase}/nutrition/log-meal`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            });
            
            const data = await response.json();
            
            if (response.ok) {
                this.app.closeModal();
                this.loadDailyNutrition(); // Refresh data
                this.app.showToast(`${mealData.name} logged successfully!`, 'success');
            } else {
                throw new Error(data.error || 'Failed to log meal');
            }
            
        } catch (error) {
            console.error('Error logging meal:', error);
            this.app.showToast('Failed to log meal. Please try again.', 'error');
        }
    }
    
    async deleteMeal(mealId) {
        if (!confirm('Are you sure you want to delete this meal entry?')) {
            return;
        }
        
        try {
            const response = await fetch(`${this.app.apiBase}/nutrition/meals/${mealId}`, {
                method: 'DELETE'
            });
            
            if (response.ok) {
                this.loadDailyNutrition(); // Refresh data
                this.app.showToast('Meal deleted successfully', 'success');
            } else {
                throw new Error('Failed to delete meal');
            }
            
        } catch (error) {
            console.error('Error deleting meal:', error);
            this.app.showToast('Failed to delete meal', 'error');
        }
    }
    
    async openNutritionGoalsModal() {
        const modalContent = `
            <div class="nutrition-goals-modal">
                <h3>Set Nutrition Goals</h3>
                <form id="nutrition-goals-form">
                    <div class="goals-grid">
                        <div class="form-group">
                            <label>Daily Calories</label>
                            <input type="number" id="goal-calories" class="form-input" value="${this.nutritionGoals.calories}" min="800" max="5000">
                        </div>
                        <div class="form-group">
                            <label>Protein (g)</label>
                            <input type="number" id="goal-protein" class="form-input" value="${this.nutritionGoals.protein}" min="20" max="300">
                        </div>
                        <div class="form-group">
                            <label>Carbs (g)</label>
                            <input type="number" id="goal-carbs" class="form-input" value="${this.nutritionGoals.carbs}" min="50" max="500">
                        </div>
                        <div class="form-group">
                            <label>Fat (g)</label>
                            <input type="number" id="goal-fat" class="form-input" value="${this.nutritionGoals.fat}" min="20" max="200">
                        </div>
                        <div class="form-group">
                            <label>Fiber (g)</label>
                            <input type="number" id="goal-fiber" class="form-input" value="${this.nutritionGoals.fiber}" min="10" max="50">
                        </div>
                        <div class="form-group">
                            <label>Sodium (mg)</label>
                            <input type="number" id="goal-sodium" class="form-input" value="${this.nutritionGoals.sodium}" min="500" max="3000">
                        </div>
                    </div>
                    
                    <div class="goal-presets">
                        <h4>Quick Presets:</h4>
                        <div class="preset-buttons">
                            <button type="button" class="btn btn-outline btn-small" onclick="app.nutritionTracker.applyGoalPreset('weight-loss')">Weight Loss</button>
                            <button type="button" class="btn btn-outline btn-small" onclick="app.nutritionTracker.applyGoalPreset('muscle-gain')">Muscle Gain</button>
                            <button type="button" class="btn btn-outline btn-small" onclick="app.nutritionTracker.applyGoalPreset('maintenance')">Maintenance</button>
                        </div>
                    </div>
                    
                    <div class="modal-actions">
                        <button type="button" class="btn btn-outline" onclick="app.closeModal()">Cancel</button>
                        <button type="submit" class="btn btn-primary">Save Goals</button>
                    </div>
                </form>
            </div>
        `;
        
        this.app.openModal('nutrition-goals-modal', modalContent, () => {
            document.getElementById('nutrition-goals-form').addEventListener('submit', (e) => {
                e.preventDefault();
                this.saveNutritionGoals();
            });
        });
    }
    
    applyGoalPreset(preset) {
        const presets = {
            'weight-loss': {
                calories: 1500,
                protein: 120,
                carbs: 150,
                fat: 50,
                fiber: 25,
                sodium: 2000
            },
            'muscle-gain': {
                calories: 2500,
                protein: 180,
                carbs: 300,
                fat: 80,
                fiber: 30,
                sodium: 2300
            },
            'maintenance': {
                calories: 2000,
                protein: 150,
                carbs: 250,
                fat: 65,
                fiber: 25,
                sodium: 2300
            }
        };
        
        const presetData = presets[preset];
        if (presetData) {
            document.getElementById('goal-calories').value = presetData.calories;
            document.getElementById('goal-protein').value = presetData.protein;
            document.getElementById('goal-carbs').value = presetData.carbs;
            document.getElementById('goal-fat').value = presetData.fat;
            document.getElementById('goal-fiber').value = presetData.fiber;
            document.getElementById('goal-sodium').value = presetData.sodium;
        }
    }
    
    async saveNutritionGoals() {
        const goals = {
            calories: parseInt(document.getElementById('goal-calories').value),
            protein: parseInt(document.getElementById('goal-protein').value),
            carbs: parseInt(document.getElementById('goal-carbs').value),
            fat: parseInt(document.getElementById('goal-fat').value),
            fiber: parseInt(document.getElementById('goal-fiber').value),
            sodium: parseInt(document.getElementById('goal-sodium').value),
            sugar: this.nutritionGoals.sugar // Keep existing sugar goal
        };
        
        try {
            const response = await fetch(`${this.app.apiBase}/nutrition/goals`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ goals })
            });
            
            if (response.ok) {
                this.nutritionGoals = goals;
                this.app.closeModal();
                this.renderNutritionDashboard();
                this.app.showToast('Nutrition goals updated successfully!', 'success');
            } else {
                throw new Error('Failed to save goals');
            }
            
        } catch (error) {
            console.error('Error saving nutrition goals:', error);
            this.app.showToast('Failed to save goals. Please try again.', 'error');
        }
    }
    
    exportNutritionData() {
        // Export last 30 days of nutrition data
        const endDate = new Date();
        const startDate = new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000);
        
        // For now, just export current day data
        const exportData = {
            date: this.currentDate.toISOString().split('T')[0],
            nutrition: this.nutritionData,
            goals: this.nutritionGoals,
            exportedAt: new Date().toISOString()
        };
        
        const exportText = JSON.stringify(exportData, null, 2);
        
        const blob = new Blob([exportText], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `nutrition-data-${this.currentDate.toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        this.app.showToast('Nutrition data exported successfully!', 'success');
    }
}