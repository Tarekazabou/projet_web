/**
 * Modal Manager
 * Handles opening, closing, and managing modal dialogs
 */

class ModalManager {
    constructor() {
        this.activeModals = [];
        this.init();
    }

    init() {
        // Set up close button listeners
        document.querySelectorAll('.modal-close').forEach(closeBtn => {
            closeBtn.addEventListener('click', () => {
                const modal = closeBtn.closest('.modal');
                if (modal) this.close(modal);
            });
        });

        // Close on backdrop click
        document.querySelectorAll('.modal').forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    this.close(modal);
                }
            });
        });

        // Close on Escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.activeModals.length > 0) {
                this.close(this.activeModals[this.activeModals.length - 1]);
            }
        });
    }

    /**
     * Open a modal
     * @param {string|HTMLElement} modalId - Modal element or ID
     * @param {string|null} content - Optional HTML content
     * @param {function|null} onOpen - Callback after opening
     */
    open(modalId, content = null, onOpen = null) {
        const modal = typeof modalId === 'string' 
            ? document.getElementById(modalId) 
            : modalId;

        if (!modal) {
            console.warn(`Modal not found: ${modalId}`);
            return null;
        }

        // Set content if provided
        if (content) {
            const target = modal.querySelector('[data-modal-body]') 
                        || modal.querySelector('.modal-body');
            if (target) {
                target.innerHTML = content;
            }
        }

        // Show modal
        modal.classList.add('active');
        this.activeModals.push(modal);
        document.body.style.overflow = 'hidden';

        // Call onOpen callback
        if (typeof onOpen === 'function') {
            onOpen(modal);
        }

        return modal;
    }

    /**
     * Close a modal
     * @param {string|HTMLElement|null} target - Modal to close (or last active if null)
     */
    close(target = null) {
        let modal = target;

        if (typeof modal === 'string') {
            modal = document.getElementById(modal);
        } else if (!modal) {
            modal = this.activeModals.pop();
        }

        if (!modal) return;

        // Hide modal
        modal.classList.remove('active');
        
        // Remove from active list
        this.activeModals = this.activeModals.filter(m => m !== modal);

        // Restore body scroll if no modals are open
        if (this.activeModals.length === 0) {
            document.body.style.overflow = '';
        }
    }

    /**
     * Close all open modals
     */
    closeAll() {
        const modals = [...this.activeModals];
        modals.forEach(modal => this.close(modal));
    }

    /**
     * Check if a modal is open
     */
    isOpen(modalId) {
        const modal = typeof modalId === 'string' 
            ? document.getElementById(modalId) 
            : modalId;
        return modal && this.activeModals.includes(modal);
    }
}

window.modalManager = new ModalManager();
