/**
 * Router - Page Navigation Manager
 * Handles switching between different pages/views
 */

class Router {
    constructor() {
        this.currentPage = 'home';
        this.pages = new Map();
        this.init();
    }

    init() {
        // Set up navigation links
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const page = e.target.dataset.page;
                if (page) {
                    this.navigateTo(page);
                }
            });
        });
    }

    /**
     * Register a page controller
     */
    register(pageName, pageController) {
        this.pages.set(pageName, pageController);
    }

    /**
     * Navigate to a page
     */
    navigateTo(pageName) {
        // Hide all pages
        document.querySelectorAll('.page').forEach(page => {
            page.classList.remove('active');
        });

        // Show target page
        const targetPage = document.getElementById(`${pageName}-page`);
        if (!targetPage) {
            console.warn(`Page not found: ${pageName}`);
            return;
        }

        targetPage.classList.add('active');
        this.currentPage = pageName;

        // Update navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.toggle('active', link.dataset.page === pageName);
        });

        // Initialize page controller if exists
        const controller = this.pages.get(pageName);
        if (controller && typeof controller.onNavigate === 'function') {
            controller.onNavigate();
        }

        console.log(`Navigated to: ${pageName}`);
    }

    /**
     * Get current page name
     */
    getCurrentPage() {
        return this.currentPage;
    }
}

window.router = new Router();
