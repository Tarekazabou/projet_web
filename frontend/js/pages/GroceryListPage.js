/**
 * Grocery List Page Controller
 * Simplified version for easier debugging
 */

class GroceryListPage {
    constructor() {
        this.initialized = false;
        this.groceryLists = [];
    }

    async init() {
        if (this.initialized) return;

        console.log('Initializing Grocery List Page...');
        this.setupEventListeners();
        this.initialized = true;
    }

    setupEventListeners() {
        // Generation options
        const fromMealPlanBtn = document.getElementById('generate-from-meal-plan');
        if (fromMealPlanBtn) {
            fromMealPlanBtn.addEventListener('click', () => this.generateFromMealPlan());
        }

        const fromRecipesBtn = document.getElementById('generate-from-recipes');
        if (fromRecipesBtn) {
            fromRecipesBtn.addEventListener('click', () => this.generateFromRecipes());
        }

        const manualBtn = document.getElementById('manual-grocery-list');
        if (manualBtn) {
            manualBtn.addEventListener('click', () => this.createManualList());
        }

        // Export options
        const exportBtn = document.getElementById('export-pdf');
        if (exportBtn) {
            exportBtn.addEventListener('click', () => this.exportToPDF());
        }

        const integrateBtn = document.getElementById('integrate-store');
        if (integrateBtn) {
            integrateBtn.addEventListener('click', () => this.integrateStore());
        }
    }

    generateFromMealPlan() {
        window.toastManager.info('Generate from meal plan feature coming soon!');
    }

    generateFromRecipes() {
        window.toastManager.info('Generate from recipes feature coming soon!');
    }

    createManualList() {
        window.toastManager.info('Manual list creation feature coming soon!');
    }

    exportToPDF() {
        window.toastManager.info('PDF export feature coming soon!');
    }

    integrateStore() {
        window.toastManager.info('Store integration feature coming soon!');
    }

    onNavigate() {
        if (!this.initialized) this.init();
    }
}

window.addEventListener('DOMContentLoaded', () => {
    const groceryPage = new GroceryListPage();
    window.router.register('grocery-list', groceryPage);
});
