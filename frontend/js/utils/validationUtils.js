/**
 * Validation Utility Functions
 */

const validationUtils = {
    /**
     * Validate email format
     */
    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    },

    /**
     * Validate API key format (Gemini)
     */
    isValidApiKey(apiKey) {
        if (!apiKey || typeof apiKey !== 'string') {
            return false;
        }
        
        const trimmed = apiKey.trim();
        
        // Check length
        if (trimmed.length < 20 || trimmed.length > 500) {
            return false;
        }
        
        // Check Gemini API key pattern
        return /^AIza[0-9A-Za-z-_]{35}$/.test(trimmed);
    },

    /**
     * Validate non-empty string
     */
    isNonEmptyString(value) {
        return typeof value === 'string' && value.trim().length > 0;
    },

    /**
     * Validate positive number
     */
    isPositiveNumber(value) {
        const num = Number(value);
        return !isNaN(num) && num > 0;
    },

    /**
     * Validate date format (YYYY-MM-DD)
     */
    isValidDate(dateString) {
        const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
        if (!dateRegex.test(dateString)) return false;
        
        const date = new Date(dateString);
        return date instanceof Date && !isNaN(date);
    },

    /**
     * Sanitize HTML to prevent XSS
     */
    sanitizeHtml(html) {
        const temp = document.createElement('div');
        temp.textContent = html;
        return temp.innerHTML;
    }
};

window.validationUtils = validationUtils;
