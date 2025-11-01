/**
 * Meal Planner Page Controller
 * Simplified version for easier debugging
 */

class MealPlannerPage {
    constructor() {
        this.initialized = false;
    }

    async init() {
        if (this.initialized) return;

        console.log('Initializing Meal Planner Page...');
        this.setupEventListeners();
        this.setDefaultDate();
        this.initialized = true;
    }

    setupEventListeners() {
        const generateBtn = document.getElementById('generate-meal-plan-btn');
        if (generateBtn) {
            generateBtn.addEventListener('click', () => this.generateMealPlan());
        }
    }

    setDefaultDate() {
        const dateInput = document.getElementById('plan-start-date');
        if (dateInput && !dateInput.value) {
            dateInput.value = window.dateUtils.today();
        }
    }

    async generateMealPlan() {
        window.toastManager.info('Meal plan generation feature coming soon!');
    }

    onNavigate() {
        if (!this.initialized) this.init();
    }
}

window.addEventListener('DOMContentLoaded', () => {
    const mealPlannerPage = new MealPlannerPage();
    window.router.register('meal-planner', mealPlannerPage);
});
