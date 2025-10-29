/**
 * Settings Management
 * Handles API key configuration and testing
 */

class SettingsManager {
    constructor() {
        this.apiBaseUrl = 'http://localhost:5000/api';
        this.isConfigured = false;
        this.init();
    }

    async init() {
        // Check API key status on load
        await this.checkApiKeyStatus();
    }

    async checkApiKeyStatus() {
        try {
            const response = await fetch(`${this.apiBaseUrl}/settings/gemini-api-key/status`);
            const data = await response.json();
            
            this.isConfigured = data.is_configured;
            
            // Update UI indicator if exists
            this.updateStatusIndicator();
            
            return this.isConfigured;
        } catch (error) {
            console.error('Error checking API key status:', error);
            return false;
        }
    }

    updateStatusIndicator() {
        const indicator = document.getElementById('api-key-status-indicator');
        if (indicator) {
            if (this.isConfigured) {
                indicator.innerHTML = `
                    <span class="status-badge status-active">
                        <i class="fas fa-check-circle"></i>
                        AI Active
                    </span>
                `;
            } else {
                indicator.innerHTML = `
                    <span class="status-badge status-inactive">
                        <i class="fas fa-exclamation-circle"></i>
                        AI Not Configured
                    </span>
                `;
            }
        }
    }

    async testApiKey(apiKey) {
        try {
            console.log('Testing API key...', this.apiBaseUrl);
            const response = await fetch(`${this.apiBaseUrl}/settings/gemini-api-key/test`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ api_key: apiKey })
            });

            console.log('Response status:', response.status);
            
            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                console.error('API error:', errorData);
                return {
                    success: false,
                    error: errorData.error || `Server error (${response.status})`
                };
            }

            const data = await response.json();
            console.log('API response:', data);
            return data;
        } catch (error) {
            console.error('Error testing API key:', error);
            return {
                success: false,
                error: `Network error: ${error.message}. Please check your connection.`
            };
        }
    }

    async saveApiKey(apiKey) {
        try {
            console.log('Saving API key...');
            const response = await fetch(`${this.apiBaseUrl}/settings/gemini-api-key/save`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ api_key: apiKey })
            });

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                console.error('Save error:', errorData);
                return {
                    success: false,
                    error: errorData.error || `Server error (${response.status})`
                };
            }

            const data = await response.json();
            console.log('Save response:', data);
            
            if (data.success) {
                this.isConfigured = true;
                this.updateStatusIndicator();
            }
            
            return data;
        } catch (error) {
            console.error('Error saving API key:', error);
            return {
                success: false,
                error: `Network error: ${error.message}`
            };
        }
    }

    async removeApiKey() {
        try {
            const response = await fetch(`${this.apiBaseUrl}/settings/gemini-api-key/remove`, {
                method: 'DELETE'
            });

            const data = await response.json();
            
            if (data.success) {
                this.isConfigured = false;
                this.updateStatusIndicator();
            }
            
            return data;
        } catch (error) {
            console.error('Error removing API key:', error);
            return {
                success: false,
                error: 'Failed to remove API key.'
            };
        }
    }

    showApiKeyModal() {
        const modal = this.createApiKeyModal();
        document.body.appendChild(modal);
        
        // Show modal
        setTimeout(() => modal.classList.add('active'), 10);
        
        // Setup event listeners
        this.setupModalListeners(modal);
    }

    createApiKeyModal() {
        const modal = document.createElement('div');
        modal.className = 'modal';
        modal.id = 'api-key-setup-modal';
        modal.innerHTML = `
            <div class="modal-content">
                <div class="modal-header">
                    <h2>
                        <i class="fas fa-key"></i>
                        Configure AI Recipe Generation
                    </h2>
                    <button class="modal-close" aria-label="Close">&times;</button>
                </div>
                <div class="modal-body">
                    <div class="api-key-setup">
                        <div class="setup-info">
                            <p>To enable AI-powered recipe generation, you need a <strong>free</strong> Google Gemini API key.</p>
                            <div class="info-box">
                                <i class="fas fa-info-circle"></i>
                                <div>
                                    <strong>Getting your FREE API key:</strong>
                                    <ol>
                                        <li>Visit <a href="https://makersuite.google.com/app/apikey" target="_blank">Google AI Studio</a></li>
                                        <li>Sign in with your Google account</li>
                                        <li>Click "Create API Key"</li>
                                        <li>Copy the key and paste it below</li>
                                    </ol>
                                    <p><small>Free tier: 60 requests/minute, 1,500/day (more than enough!)</small></p>
                                </div>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="gemini-api-key-input">
                                <i class="fas fa-key"></i>
                                Gemini API Key
                            </label>
                            <input 
                                type="password" 
                                id="gemini-api-key-input" 
                                class="form-input" 
                                placeholder="Paste your API key here..."
                            >
                            <button 
                                type="button" 
                                class="btn-toggle-visibility" 
                                id="toggle-api-key-visibility"
                                title="Show/Hide API key"
                            >
                                <i class="fas fa-eye"></i>
                            </button>
                        </div>

                        <div class="api-key-actions">
                            <button class="btn btn-outline" id="test-api-key-btn" disabled>
                                <i class="fas fa-vial"></i>
                                Test Connection
                            </button>
                            <button class="btn btn-primary" id="save-api-key-btn" disabled>
                                <i class="fas fa-save"></i>
                                Test & Save
                            </button>
                        </div>

                        <div class="api-key-status" id="api-key-status" style="display: none;">
                            <!-- Status messages will appear here -->
                        </div>

                        <div class="current-status" id="current-api-status">
                            <strong>Current Status:</strong>
                            <span class="status-badge status-inactive">
                                <i class="fas fa-times-circle"></i>
                                Not Configured
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        `;
        return modal;
    }

    setupModalListeners(modal) {
        const closeBtn = modal.querySelector('.modal-close');
        const apiKeyInput = modal.querySelector('#gemini-api-key-input');
        const toggleVisibilityBtn = modal.querySelector('#toggle-api-key-visibility');
        const testBtn = modal.querySelector('#test-api-key-btn');
        const saveBtn = modal.querySelector('#save-api-key-btn');
        const statusDiv = modal.querySelector('#api-key-status');

        // Close modal
        closeBtn.addEventListener('click', () => {
            modal.classList.remove('active');
            setTimeout(() => modal.remove(), 300);
        });

        // Close on backdrop click
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.classList.remove('active');
                setTimeout(() => modal.remove(), 300);
            }
        });

        // Toggle password visibility
        toggleVisibilityBtn.addEventListener('click', () => {
            const input = apiKeyInput;
            const icon = toggleVisibilityBtn.querySelector('i');
            
            if (input.type === 'password') {
                input.type = 'text';
                icon.classList.remove('fa-eye');
                icon.classList.add('fa-eye-slash');
            } else {
                input.type = 'password';
                icon.classList.remove('fa-eye-slash');
                icon.classList.add('fa-eye');
            }
        });

        // Enable buttons when API key is entered
        apiKeyInput.addEventListener('input', () => {
            const hasValue = apiKeyInput.value.trim().length > 0;
            testBtn.disabled = !hasValue;
            saveBtn.disabled = !hasValue;
        });

        // Test API key
        testBtn.addEventListener('click', async () => {
            await this.handleTestApiKey(apiKeyInput, statusDiv, testBtn);
        });

        // Save API key (test first, then save)
        saveBtn.addEventListener('click', async () => {
            await this.handleSaveApiKey(apiKeyInput, statusDiv, saveBtn, modal);
        });

        // Update current status
        this.updateModalStatus(modal);
    }

    async handleTestApiKey(input, statusDiv, button) {
        const apiKey = input.value.trim();
        
        if (!apiKey) {
            this.showStatus(statusDiv, 'error', 'Please enter an API key');
            return;
        }

        // Show loading
        button.disabled = true;
        button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Testing...';
        this.showStatus(statusDiv, 'loading', 'Testing your API key with Google Gemini...');

        // Test the key
        const result = await this.testApiKey(apiKey);

        // Restore button
        button.disabled = false;
        button.innerHTML = '<i class="fas fa-vial"></i> Test Connection';

        // Show result
        if (result.success) {
            this.showStatus(statusDiv, 'success', 
                `✅ Success! API key is valid and working.<br><small>Test response: "${result.test_response}"</small>`
            );
        } else {
            this.showStatus(statusDiv, 'error', 
                `❌ ${result.error}<br><small>${result.details || ''}</small>`
            );
        }
    }

    async handleSaveApiKey(input, statusDiv, button, modal) {
        const apiKey = input.value.trim();
        
        if (!apiKey) {
            this.showStatus(statusDiv, 'error', 'Please enter an API key');
            return;
        }

        // Show loading
        button.disabled = true;
        button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Testing & Saving...';
        this.showStatus(statusDiv, 'loading', 'Step 1/2: Testing API key...');

        // Test first
        const testResult = await this.testApiKey(apiKey);

        if (!testResult.success) {
            button.disabled = false;
            button.innerHTML = '<i class="fas fa-save"></i> Test & Save';
            this.showStatus(statusDiv, 'error', 
                `❌ Test failed: ${testResult.error}<br><small>Please check your API key and try again.</small>`
            );
            return;
        }

        // If test passed, save it
        this.showStatus(statusDiv, 'loading', 'Step 2/2: Saving to configuration...');
        
        const saveResult = await this.saveApiKey(apiKey);

        // Restore button
        button.disabled = false;
        button.innerHTML = '<i class="fas fa-save"></i> Test & Save';

        if (saveResult.success) {
            this.showStatus(statusDiv, 'success', 
                `🎉 Success! Your API key has been saved and AI recipe generation is now active!<br><small>You can now close this window.</small>`
            );
            
            // Update modal status
            this.updateModalStatus(modal);
            
            // Show success toast
            this.showToast('AI recipe generation is now active!', 'success');
            
            // Auto-close after 3 seconds
            setTimeout(() => {
                modal.classList.remove('active');
                setTimeout(() => modal.remove(), 300);
            }, 3000);
        } else {
            this.showStatus(statusDiv, 'error', 
                `❌ Failed to save: ${saveResult.error}`
            );
        }
    }

    updateModalStatus(modal) {
        const currentStatus = modal.querySelector('#current-api-status');
        if (currentStatus) {
            const statusBadge = currentStatus.querySelector('.status-badge');
            if (this.isConfigured) {
                statusBadge.className = 'status-badge status-active';
                statusBadge.innerHTML = '<i class="fas fa-check-circle"></i> Configured & Active';
            } else {
                statusBadge.className = 'status-badge status-inactive';
                statusBadge.innerHTML = '<i class="fas fa-times-circle"></i> Not Configured';
            }
        }
    }

    showStatus(statusDiv, type, message) {
        statusDiv.style.display = 'block';
        statusDiv.className = `api-key-status status-${type}`;
        statusDiv.innerHTML = message;
    }

    showToast(message, type = 'info') {
        // Try to use existing toast system if available
        if (window.app && window.app.showToast) {
            window.app.showToast(message, type);
        } else {
            // Fallback: simple alert
            alert(message);
        }
    }
}

// Initialize settings manager
window.settingsManager = new SettingsManager();

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SettingsManager;
}
