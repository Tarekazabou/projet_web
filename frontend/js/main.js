/**
 * Main Application Entry Point
 * Simplified and organized for easier debugging
 */

console.log('🚀 Recipe Meal Planner App Starting...');

// Main App Initialization
document.addEventListener('DOMContentLoaded', () => {
    console.log('✅ DOM Content Loaded');
    
    // Initialize core managers (already instantiated in their files)
    console.log('✅ Core managers initialized:');
    console.log('   - Router:', window.router ? '✓' : '✗');
    console.log('   - Modal Manager:', window.modalManager ? '✓' : '✗');
    console.log('   - Toast Manager:', window.toastManager ? '✓' : '✗');
    console.log('   - Loading Manager:', window.loadingManager ? '✓' : '✗');
    console.log('   - API Client:', window.apiClient ? '✓' : '✗');
    
    // Set up global UI event listeners
    setupGlobalUI();
    
    // Initialize authentication
    if (window.authManager) {
        window.authManager.init();
        console.log('✅ Auth Manager initialized');
    }
    
    // Initialize settings
    if (window.settingsManager) {
        window.settingsManager.init();
        console.log('✅ Settings Manager initialized');
    }
    
    // Set default dates for date inputs
    setDefaultDates();
    
    console.log('✅ Application Ready!');
});

/**
 * Set up global UI event listeners
 */
function setupGlobalUI() {
    // User profile button
    const profileBtn = document.getElementById('user-profile-btn');
    if (profileBtn) {
        profileBtn.addEventListener('click', () => {
            if (window.authManager && window.authManager.currentUser) {
                window.toastManager.info('User profile feature coming soon!');
            } else {
                window.modalManager.open('auth-modal');
            }
        });
    }
    
    // User preferences button
    const preferencesBtn = document.getElementById('user-preferences-btn');
    if (preferencesBtn) {
        preferencesBtn.addEventListener('click', () => {
            window.toastManager.info('User preferences feature coming soon!');
        });
    }
    
    // AI Setup button
    const aiSetupBtn = document.getElementById('ai-setup-btn');
    if (aiSetupBtn) {
        aiSetupBtn.addEventListener('click', () => {
            if (window.settingsManager) {
                window.settingsManager.showApiKeyModal();
            }
        });
    }
    
    // Logout button
    const logoutBtn = document.getElementById('logout-btn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', () => {
            if (window.authManager) {
                window.authManager.logout();
            }
        });
    }
    
    console.log('✅ Global UI listeners set up');
}

/**
 * Set default dates for all date inputs
 */
function setDefaultDates() {
    const today = window.dateUtils?.today() || new Date().toISOString().split('T')[0];
    
    document.querySelectorAll('input[type="date"]').forEach(input => {
        if (!input.value) {
            input.value = today;
        }
    });
}

/**
 * Global error handler
 */
window.addEventListener('error', (event) => {
    console.error('Global error:', event.error);
    if (window.toastManager) {
        window.toastManager.error('An unexpected error occurred');
    }
});

/**
 * Global unhandled promise rejection handler
 */
window.addEventListener('unhandledrejection', (event) => {
    console.error('Unhandled promise rejection:', event.reason);
    if (window.toastManager) {
        window.toastManager.error('An unexpected error occurred');
    }
});
