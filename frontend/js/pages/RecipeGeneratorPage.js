/**
 * Recipe Generator Page Controller
 * Simplified version for easier debugging
 */

class RecipeGeneratorPage {
    constructor() {
        this.initialized = false;
        this.selectedIngredients = [];
    }

    async init() {
        if (this.initialized) return;

        console.log('Initializing Recipe Generator Page...');
        this.setupEventListeners();
        this.initialized = true;
    }

    setupEventListeners() {
        // Ingredient input
        const input = document.getElementById('ingredient-input');
        if (input) {
            input.addEventListener('keypress', (e) => {
                if (e.key === 'Enter' && e.target.value.trim()) {
                    this.addIngredient(e.target.value.trim());
                    e.target.value = '';
                }
            });
        }

        // Generate button
        const generateBtn = document.getElementById('generate-recipes-btn');
        if (generateBtn) {
            generateBtn.addEventListener('click', () => this.generateRecipes());
        }
    }

    addIngredient(ingredient) {
        if (!this.selectedIngredients.includes(ingredient)) {
            this.selectedIngredients.push(ingredient);
            this.renderSelectedIngredients();
        }
    }

    removeIngredient(ingredient) {
        this.selectedIngredients = this.selectedIngredients.filter(i => i !== ingredient);
        this.renderSelectedIngredients();
    }

    renderSelectedIngredients() {
        const container = document.getElementById('selected-ingredients');
        if (!container) return;

        container.innerHTML = this.selectedIngredients.map(ing => `
            <span class="ingredient-tag">
                ${ing}
                <button onclick="window.recipeGeneratorPage.removeIngredient('${ing}')" class="remove-tag">×</button>
            </span>
        `).join('');
    }

    async generateRecipes() {
        if (this.selectedIngredients.length === 0) {
            window.toastManager.warning('Please add at least one ingredient');
            return;
        }

        window.toastManager.info('Recipe generation feature coming soon!');
    }

    onNavigate() {
        if (!this.initialized) this.init();
    }
}

window.addEventListener('DOMContentLoaded', () => {
    window.recipeGeneratorPage = new RecipeGeneratorPage();
    window.router.register('recipe-generator', window.recipeGeneratorPage);
});
