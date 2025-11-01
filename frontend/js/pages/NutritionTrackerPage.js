/**
 * Nutrition Tracker Page Controller
 * Simplified version for easier debugging
 */

class NutritionTrackerPage {
    constructor() {
        this.initialized = false;
        this.currentDate = window.dateUtils?.today() || new Date().toISOString().split('T')[0];
    }

    async init() {
        if (this.initialized) return;

        console.log('Initializing Nutrition Tracker Page...');
        this.setupEventListeners();
        this.setDefaultDate();
        this.initialized = true;
    }

    setupEventListeners() {
        // Date navigation
        const prevBtn = document.getElementById('prev-day');
        if (prevBtn) {
            prevBtn.addEventListener('click', () => this.changeDate(-1));
        }

        const nextBtn = document.getElementById('next-day');
        if (nextBtn) {
            nextBtn.addEventListener('click', () => this.changeDate(1));
        }

        const dateInput = document.getElementById('tracking-date');
        if (dateInput) {
            dateInput.addEventListener('change', (e) => {
                this.currentDate = e.target.value;
                this.loadNutritionData();
            });
        }

        // Set goals button
        const goalsBtn = document.getElementById('set-goals-btn');
        if (goalsBtn) {
            goalsBtn.addEventListener('click', () => this.openGoalsModal());
        }
    }

    setDefaultDate() {
        const dateInput = document.getElementById('tracking-date');
        if (dateInput) {
            dateInput.value = this.currentDate;
        }
    }

    changeDate(days) {
        const date = new Date(this.currentDate);
        date.setDate(date.getDate() + days);
        this.currentDate = date.toISOString().split('T')[0];
        
        const dateInput = document.getElementById('tracking-date');
        if (dateInput) {
            dateInput.value = this.currentDate;
        }
        
        this.loadNutritionData();
    }

    async loadNutritionData() {
        window.toastManager.info('Nutrition tracking feature coming soon!');
    }

    openGoalsModal() {
        window.toastManager.info('Set goals feature coming soon!');
    }

    onNavigate() {
        if (!this.initialized) this.init();
    }
}

window.addEventListener('DOMContentLoaded', () => {
    const nutritionPage = new NutritionTrackerPage();
    window.router.register('nutrition-tracker', nutritionPage);
});
