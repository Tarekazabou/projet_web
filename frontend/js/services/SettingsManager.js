/**
 * Settings Manager
 * Simplified version for API key configuration
 */

class SettingsManager {
    constructor() {
        this.isConfigured = false;
        this.apiKey = null;
    }

    async init() {
        console.log('Initializing Settings Manager...');
        
        // Load saved API key
        this.apiKey = window.storageUtils?.load('api_key');
        
        // Check API key status
        await this.checkApiKeyStatus();
    }

    async checkApiKeyStatus() {
        try {
            const data = await window.apiClient.checkApiKeyStatus();
            this.isConfigured = data.configured || false;
            this.updateApiKeyIndicator();
        } catch (error) {
            console.error('Error checking API key status:', error);
            this.isConfigured = false;
            this.updateApiKeyIndicator();
        }
    }

    updateApiKeyIndicator() {
        const indicator = document.getElementById('api-key-status-indicator');
        if (!indicator) return;

        if (this.isConfigured) {
            indicator.innerHTML = '<span class="status-badge success">AI Ready</span>';
        } else {
            indicator.innerHTML = '<span class="status-badge warning">AI Not Configured</span>';
        }
    }

    showApiKeyModal() {
        const modalContent = `
            <div class="api-key-setup">
                <h3>Configure Gemini API Key</h3>
                <p>Enter your Google Gemini API key to enable AI-powered recipe generation.</p>
                
                <div class="form-group">
                    <label for="api-key-input">API Key</label>
                    <input type="text" id="api-key-input" class="form-input" placeholder="AIza...">
                </div>
                
                <div class="form-actions">
                    <button class="btn btn-outline" onclick="window.modalManager.close()">Cancel</button>
                    <button class="btn btn-primary" id="save-api-key-btn">Save & Test</button>
                </div>
                
                <div id="api-key-status"></div>
            </div>
        `;

        window.modalManager.open('add-ingredient-modal', modalContent, (modal) => {
            const saveBtn = modal.querySelector('#save-api-key-btn');
            const input = modal.querySelector('#api-key-input');
            
            if (saveBtn && input) {
                saveBtn.addEventListener('click', async () => {
                    await this.saveAndTestApiKey(input.value);
                });
            }
        });
    }

    async saveAndTestApiKey(apiKey) {
        const statusEl = document.getElementById('api-key-status');
        
        if (!apiKey || !apiKey.trim()) {
            if (statusEl) {
                statusEl.innerHTML = '<p class="error">Please enter an API key</p>';
            }
            return;
        }

        try {
            window.loadingManager.show();
            
            // Test the API key
            const result = await window.apiClient.testApiKey(apiKey);
            
            if (result.valid) {
                // Save the API key
                await window.apiClient.saveApiKey(apiKey);
                window.storageUtils.save('api_key', apiKey);
                
                this.apiKey = apiKey;
                this.isConfigured = true;
                this.updateApiKeyIndicator();
                
                window.toastManager.success('API key saved successfully!');
                window.modalManager.close();
            } else {
                if (statusEl) {
                    statusEl.innerHTML = '<p class="error">Invalid API key. Please check and try again.</p>';
                }
            }
        } catch (error) {
            console.error('Error saving API key:', error);
            if (statusEl) {
                statusEl.innerHTML = '<p class="error">Failed to save API key. Please try again.</p>';
            }
        } finally {
            window.loadingManager.hide();
        }
    }
}

// Create global instance
window.settingsManager = new SettingsManager();
