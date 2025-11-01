/**
 * Date Utility Functions
 */

const dateUtils = {
    /**
     * Get current date in YYYY-MM-DD format
     */
    today() {
        return new Date().toISOString().split('T')[0];
    },

    /**
     * Get date N days from now
     */
    daysFromNow(days) {
        const date = new Date();
        date.setDate(date.getDate() + days);
        return date.toISOString().split('T')[0];
    },

    /**
     * Format date for display
     */
    formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    },

    /**
     * Get days until date
     */
    daysUntil(dateString) {
        const target = new Date(dateString);
        const now = new Date();
        const diffTime = target - now;
        return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    },

    /**
     * Check if date is expired
     */
    isExpired(dateString) {
        return this.daysUntil(dateString) < 0;
    },

    /**
     * Check if date is expiring soon (within 3 days)
     */
    isExpiringSoon(dateString) {
        const days = this.daysUntil(dateString);
        return days >= 0 && days <= 3;
    },

    /**
     * Get freshness status
     */
    getFreshnessStatus(dateString) {
        if (this.isExpired(dateString)) return 'expired';
        if (this.isExpiringSoon(dateString)) return 'expiring-soon';
        return 'fresh';
    }
};

window.dateUtils = dateUtils;
