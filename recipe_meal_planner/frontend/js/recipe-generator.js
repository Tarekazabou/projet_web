// ===== RECIPE GENERATOR COMPONENT =====
class RecipeGenerator {
    constructor(app) {
        this.app = app;
        this.selectedIngredients = [];
        this.isGenerating = false;
    }
    
    initialize() {
        this.setupEventListeners();
        this.loadCategories();
    }
    
    setupEventListeners() {
        // Ingredient input
        const ingredientInput = document.getElementById('ingredient-input');
        if (ingredientInput) {
            ingredientInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.addIngredient(e.target.value.trim());
                    e.target.value = '';
                }
            });
            
            // Add autocomplete functionality
            ingredientInput.addEventListener('input', (e) => {
                this.handleIngredientAutocomplete(e.target.value);
            });
        }
        
        // Generate recipes button
        const generateBtn = document.getElementById('generate-recipes-btn');
        if (generateBtn) {
            generateBtn.addEventListener('click', () => {
                this.generateRecipes();
            });
        }
        
        // Dietary preferences checkboxes
        document.querySelectorAll('#dietary-preferences input[type="checkbox"]').forEach(checkbox => {
            checkbox.addEventListener('change', () => {
                this.updateGenerateButton();
            });
        });
    }
    
    async loadCategories() {
        try {
            const response = await fetch(`${this.app.apiBase}/recipes/categories`);
            const data = await response.json();
            
            if (data.dietary_tags) {
                this.updateDietaryPreferences(data.dietary_tags);
            }
        } catch (error) {
            console.error('Error loading categories:', error);
        }
    }
    
    updateDietaryPreferences(tags) {
        const container = document.getElementById('dietary-preferences');
        if (!container || tags.length === 0) return;
        
        // Add any new dietary tags that aren't already in the form
        const existingTags = Array.from(container.querySelectorAll('input[type="checkbox"]')).map(cb => cb.value);
        
        tags.forEach(tag => {
            if (!existingTags.includes(tag)) {
                const label = document.createElement('label');
                label.className = 'preference-item';
                label.innerHTML = `
                    <input type="checkbox" value="${tag}">
                    <span class="checkmark"></span>
                    ${tag.charAt(0).toUpperCase() + tag.slice(1).replace('-', ' ')}
                `;
                container.appendChild(label);
            }
        });
    }
    
    handleIngredientAutocomplete(query) {
        if (query.length < 2) {
            this.hideIngredientSuggestions();
            return;
        }
        
        // Common ingredients for autocomplete
        const commonIngredients = [
            'quinoa', 'rice', 'chicken breast', 'salmon', 'avocado', 'spinach', 'broccoli',
            'sweet potato', 'olive oil', 'garlic', 'onion', 'tomato', 'bell pepper',
            'mushrooms', 'carrots', 'zucchini', 'cucumber', 'lettuce', 'kale',
            'chickpeas', 'black beans', 'lentils', 'tofu', 'eggs', 'milk', 'cheese',
            'yogurt', 'banana', 'apple', 'berries', 'lemon', 'ginger', 'herbs'
        ];
        
        const suggestions = commonIngredients
            .filter(ingredient => 
                ingredient.toLowerCase().includes(query.toLowerCase()) &&
                !this.selectedIngredients.includes(ingredient)
            )
            .slice(0, 8);
        
        if (suggestions.length > 0) {
            this.showIngredientSuggestions(suggestions, query);
        } else {
            this.hideIngredientSuggestions();
        }
    }
    
    showIngredientSuggestions(suggestions, query) {
        let suggestionsContainer = document.getElementById('ingredient-suggestions');
        
        if (!suggestionsContainer) {
            suggestionsContainer = document.createElement('div');
            suggestionsContainer.id = 'ingredient-suggestions';
            suggestionsContainer.className = 'search-suggestions';
            
            const ingredientInput = document.getElementById('ingredient-input');
            ingredientInput.parentNode.style.position = 'relative';
            ingredientInput.parentNode.appendChild(suggestionsContainer);
        }
        
        suggestionsContainer.innerHTML = suggestions.map(ingredient => `
            <div class="suggestion-item" data-ingredient="${ingredient}">
                ${this.highlightMatch(ingredient, query)}
            </div>
        `).join('');
        
        // Add click listeners
        suggestionsContainer.querySelectorAll('.suggestion-item').forEach(item => {
            item.addEventListener('click', () => {
                const ingredient = item.dataset.ingredient;
                this.addIngredient(ingredient);
                document.getElementById('ingredient-input').value = '';
                this.hideIngredientSuggestions();
            });
        });
        
        suggestionsContainer.style.display = 'block';
    }
    
    highlightMatch(text, query) {
        const regex = new RegExp(`(${query})`, 'gi');
        return text.replace(regex, '<strong>$1</strong>');
    }
    
    hideIngredientSuggestions() {
        const suggestionsContainer = document.getElementById('ingredient-suggestions');
        if (suggestionsContainer) {
            suggestionsContainer.style.display = 'none';
        }
    }
    
    addIngredient(ingredient) {
        if (!ingredient || this.selectedIngredients.includes(ingredient.toLowerCase())) {
            return;
        }
        
        const normalizedIngredient = ingredient.toLowerCase();
        this.selectedIngredients.push(normalizedIngredient);
        this.renderSelectedIngredients();
        this.updateGenerateButton();
    }
    
    removeIngredient(ingredient) {
        this.selectedIngredients = this.selectedIngredients.filter(ing => ing !== ingredient);
        this.renderSelectedIngredients();
        this.updateGenerateButton();
    }
    
    renderSelectedIngredients() {
        const container = document.getElementById('selected-ingredients');
        if (!container) return;
        
        container.innerHTML = this.selectedIngredients.map(ingredient => `
            <span class="ingredient-tag">
                ${ingredient}
                <i class="fas fa-times remove-ingredient" onclick="app.recipeGenerator.removeIngredient('${ingredient}')"></i>
            </span>
        `).join('');
    }
    
    updateGenerateButton() {
        const generateBtn = document.getElementById('generate-recipes-btn');
        if (!generateBtn) return;
        
        const hasIngredients = this.selectedIngredients.length > 0;
        const hasPreferences = document.querySelectorAll('#dietary-preferences input[type="checkbox"]:checked').length > 0;
        
        if (hasIngredients || hasPreferences) {
            generateBtn.disabled = false;
            generateBtn.innerHTML = `
                <i class="fas fa-magic"></i>
                Generate Recipes (${this.selectedIngredients.length} ingredients)
            `;
        } else {
            generateBtn.disabled = false; // Allow generation even without ingredients
            generateBtn.innerHTML = `
                <i class="fas fa-magic"></i>
                Generate Recipes
            `;
        }
    }
    
    async generateRecipes() {
        if (this.isGenerating) return;
        
        this.isGenerating = true;
        const generateBtn = document.getElementById('generate-recipes-btn');
        const resultsSection = document.getElementById('recipe-results');
        
        // Update button state
        if (generateBtn) {
            generateBtn.disabled = true;
            generateBtn.innerHTML = `
                <i class="fas fa-spinner fa-spin"></i>
                Generating Recipes...
            `;
        }
        
        try {
            // Collect form data
            const requestData = {
                ingredients: this.selectedIngredients,
                dietary_preferences: Array.from(document.querySelectorAll('#dietary-preferences input[type="checkbox"]:checked')).map(cb => cb.value),
                max_cooking_time: parseInt(document.getElementById('max-cooking-time').value),
                difficulty: document.getElementById('difficulty-level').value,
                servings: parseInt(document.getElementById('servings').value)
            };
            
            // Make API request
            const response = await fetch(`${this.app.apiBase}/recipes/generate`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            });
            
            const data = await response.json();
            
            if (response.ok) {
                this.renderRecipeResults(data.recipes, data.suggestions);
            } else {
                throw new Error(data.error || 'Failed to generate recipes');
            }
            
        } catch (error) {
            console.error('Error generating recipes:', error);
            this.app.showToast('Failed to generate recipes. Please try again.', 'error');
            
            if (resultsSection) {
                resultsSection.innerHTML = `
                    <div class="empty-state">
                        <i class="fas fa-exclamation-triangle empty-state-icon"></i>
                        <h3 class="empty-state-title">Generation Failed</h3>
                        <p class="empty-state-description">
                            We couldn't generate recipes at this time. Please check your connection and try again.
                        </p>
                        <button class="btn btn-primary" onclick="app.recipeGenerator.generateRecipes()">
                            Try Again
                        </button>
                    </div>
                `;
            }
        } finally {
            this.isGenerating = false;
            
            // Reset button state
            if (generateBtn) {
                generateBtn.disabled = false;
                generateBtn.innerHTML = `
                    <i class="fas fa-magic"></i>
                    Generate Recipes
                `;
            }
        }
    }
    
    renderRecipeResults(recipes, suggestions = null) {
        const resultsSection = document.getElementById('recipe-results');
        if (!resultsSection) return;
        
        if (!recipes || recipes.length === 0) {
            resultsSection.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-search empty-state-icon"></i>
                    <h3 class="empty-state-title">No Recipes Found</h3>
                    <p class="empty-state-description">
                        We couldn't find recipes matching your criteria. Try adjusting your ingredients or preferences.
                    </p>
                    ${suggestions ? this.renderSuggestions(suggestions) : ''}
                </div>
            `;
            return;
        }
        
        resultsSection.innerHTML = `
            <div class="results-header">
                <h3>Generated Recipes (${recipes.length})</h3>
                <div class="results-actions">
                    <button class="btn btn-outline" onclick="app.recipeGenerator.saveSearch()">
                        <i class="fas fa-bookmark"></i>
                        Save Search
                    </button>
                    <button class="btn btn-outline" onclick="app.recipeGenerator.exportRecipes()">
                        <i class="fas fa-download"></i>
                        Export
                    </button>
                </div>
            </div>
            <div class="recipes-grid">
                ${recipes.map(recipe => this.createGeneratedRecipeCard(recipe)).join('')}
            </div>
        `;
        
        // Add click listeners
        resultsSection.querySelectorAll('.recipe-card').forEach(card => {
            card.addEventListener('click', () => {
                const recipeId = card.dataset.recipeId;
                this.app.openRecipeModal(recipeId);
            });
        });
        
        // Scroll to results
        resultsSection.scrollIntoView({ behavior: 'smooth' });
    }
    
    createGeneratedRecipeCard(recipe) {
        const tags = recipe.dietary_tags || [];
        const rating = recipe.rating || 0;
        const reviewCount = recipe.review_count || 0;
        const relevanceScore = recipe.relevance_score || 0;
        
        return `
            <div class="recipe-card generated-recipe" data-recipe-id="${recipe._id}">
                <div class="recipe-image">
                    <i class="fas fa-camera placeholder-icon"></i>
                    <div class="recipe-rating">
                        <i class="fas fa-star"></i>
                        ${rating.toFixed(1)}
                    </div>
                    <div class="relevance-score">
                        <i class="fas fa-bullseye"></i>
                        ${relevanceScore.toFixed(0)}% match
                    </div>
                </div>
                <div class="recipe-content">
                    <h3 class="recipe-title">${recipe.title}</h3>
                    <div class="recipe-meta">
                        <span><i class="fas fa-clock"></i> ${(recipe.cooking_time || 0) + (recipe.prep_time || 0)} min</span>
                        <span><i class="fas fa-users"></i> ${recipe.servings} servings</span>
                        <span><i class="fas fa-signal"></i> ${recipe.difficulty}</span>
                    </div>
                    <div class="recipe-tags">
                        ${tags.slice(0, 3).map(tag => `<span class="tag tag-${tag}">${tag}</span>`).join('')}
                    </div>
                    <div class="matched-ingredients">
                        <small>Matched ingredients: ${this.getMatchedIngredients(recipe)}</small>
                    </div>
                    <div class="recipe-actions">
                        <button class="btn btn-outline btn-small" onclick="event.stopPropagation(); app.saveRecipe('${recipe._id}')">
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
    
    getMatchedIngredients(recipe) {
        const recipeIngredients = recipe.ingredients.map(ing => ing.name.toLowerCase());
        const matched = this.selectedIngredients.filter(ingredient => 
            recipeIngredients.some(recipeIng => 
                recipeIng.includes(ingredient) || ingredient.includes(recipeIng)
            )
        );
        
        return matched.length > 0 ? matched.slice(0, 3).join(', ') : 'Based on preferences';
    }
    
    renderSuggestions(suggestions) {
        if (!suggestions || (!suggestions.alternative_ingredients && !suggestions.recipe_ideas)) {
            return '';
        }
        
        let suggestionsHtml = '<div class="generation-suggestions">';
        
        if (suggestions.alternative_ingredients && suggestions.alternative_ingredients.length > 0) {
            suggestionsHtml += `
                <div class="suggestion-group">
                    <h4>Try these ingredient alternatives:</h4>
                    <div class="alternative-ingredients">
                        ${suggestions.alternative_ingredients.map(alt => `
                            <div class="alternative-item">
                                <strong>${alt.original}</strong> → 
                                ${alt.alternatives.slice(0, 2).join(', ')}
                            </div>
                        `).join('')}
                    </div>
                </div>
            `;
        }
        
        if (suggestions.recipe_ideas && suggestions.recipe_ideas.length > 0) {
            suggestionsHtml += `
                <div class="suggestion-group">
                    <h4>Popular recipes in your dietary category:</h4>
                    <div class="recipe-suggestions">
                        ${suggestions.recipe_ideas.map(recipe => `
                            <button class="btn btn-outline btn-small" onclick="app.openRecipeModal('${recipe.id}')">
                                ${recipe.title}
                            </button>
                        `).join('')}
                    </div>
                </div>
            `;
        }
        
        suggestionsHtml += '</div>';
        return suggestionsHtml;
    }
    
    saveSearch() {
        const searchData = {
            ingredients: this.selectedIngredients,
            dietary_preferences: Array.from(document.querySelectorAll('#dietary-preferences input[type="checkbox"]:checked')).map(cb => cb.value),
            max_cooking_time: parseInt(document.getElementById('max-cooking-time').value),
            difficulty: document.getElementById('difficulty-level').value,
            servings: parseInt(document.getElementById('servings').value),
            timestamp: new Date().toISOString()
        };
        
        // Save to localStorage for now
        const savedSearches = JSON.parse(localStorage.getItem('savedRecipeSearches') || '[]');
        savedSearches.unshift(searchData);
        
        // Keep only last 10 searches
        if (savedSearches.length > 10) {
            savedSearches.splice(10);
        }
        
        localStorage.setItem('savedRecipeSearches', JSON.stringify(savedSearches));
        this.app.showToast('Search saved successfully!', 'success');
    }
    
    exportRecipes() {
        const recipes = Array.from(document.querySelectorAll('.generated-recipe')).map(card => {
            return {
                title: card.querySelector('.recipe-title').textContent,
                id: card.dataset.recipeId
            };
        });
        
        if (recipes.length === 0) {
            this.app.showToast('No recipes to export', 'warning');
            return;
        }
        
        // Create simple text export
        const exportText = `Recipe Search Results (${new Date().toLocaleDateString()})\n\n` +
            `Ingredients: ${this.selectedIngredients.join(', ')}\n` +
            `Dietary Preferences: ${Array.from(document.querySelectorAll('#dietary-preferences input[type="checkbox"]:checked')).map(cb => cb.value).join(', ')}\n\n` +
            `Recipes Found:\n` +
            recipes.map((recipe, index) => `${index + 1}. ${recipe.title}`).join('\n');
        
        // Download as text file
        const blob = new Blob([exportText], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `recipe-search-${Date.now()}.txt`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        this.app.showToast('Recipes exported successfully!', 'success');
    }
    
    // Quick ingredient buttons
    addQuickIngredient(ingredient) {
        this.addIngredient(ingredient);
    }
    
    clearAllIngredients() {
        this.selectedIngredients = [];
        this.renderSelectedIngredients();
        this.updateGenerateButton();
    }
    
    // Preset dietary combinations
    applyDietaryPreset(preset) {
        // Clear all checkboxes first
        document.querySelectorAll('#dietary-preferences input[type="checkbox"]').forEach(cb => {
            cb.checked = false;
        });
        
        // Apply preset
        const presets = {
            'weight-loss': ['low-sodium', 'high-protein', 'low-carb'],
            'muscle-gain': ['high-protein', 'high-calorie'],
            'heart-healthy': ['low-sodium', 'mediterranean', 'low-fat'],
            'diabetic-friendly': ['low-sugar', 'low-carb', 'high-fiber']
        };
        
        if (presets[preset]) {
            presets[preset].forEach(pref => {
                const checkbox = document.querySelector(`#dietary-preferences input[value="${pref}"]`);
                if (checkbox) {
                    checkbox.checked = true;
                }
            });
        }
        
        this.updateGenerateButton();
    }
}