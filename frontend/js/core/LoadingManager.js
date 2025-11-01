/**
 * Loading Manager
 * Handles displaying loading states
 */

class LoadingManager {
    constructor() {
        this.overlay = document.getElementById('loading-overlay');
        this.loadingCount = 0;
    }

    /**
     * Show loading overlay
     */
    show() {
        this.loadingCount++;
        if (this.overlay) {
            this.overlay.classList.add('active');
        }
    }

    /**
     * Hide loading overlay
     */
    hide() {
        this.loadingCount = Math.max(0, this.loadingCount - 1);
        
        if (this.loadingCount === 0 && this.overlay) {
            this.overlay.classList.remove('active');
        }
    }

    /**
     * Force hide (reset counter)
     */
    forceHide() {
        this.loadingCount = 0;
        if (this.overlay) {
            this.overlay.classList.remove('active');
        }
    }
}

window.loadingManager = new LoadingManager();
