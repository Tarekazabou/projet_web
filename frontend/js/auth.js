import { app as firebaseApp } from './firebase-init.js';
import {
    getAuth,
    onAuthStateChanged,
    signInWithEmailAndPassword,
    createUserWithEmailAndPassword,
    updateProfile,
    signOut
} from "https://www.gstatic.com/firebasejs/12.4.0/firebase-auth.js";

class AuthManager {
    constructor() {
        this.auth = getAuth(firebaseApp);
        this.appInstance = null;
        this.currentFirebaseUser = null;
        this.latestAuthState = null;

        document.addEventListener('DOMContentLoaded', () => this.setupUI());

        onAuthStateChanged(this.auth, async (user) => {
            let token = null;
            if (user) {
                try {
                    token = await user.getIdToken();
                } catch (error) {
                    console.error('Failed to fetch Firebase ID token:', error);
                }
            }

            this.currentFirebaseUser = user;
            this.latestAuthState = { user, token };
            this.notifyApp();
        });
    }

    registerApp(appInstance) {
        this.appInstance = appInstance;
        if (this.latestAuthState) {
            this.appInstance.handleAuthStateChange(
                this.latestAuthState.user,
                this.latestAuthState.token
            );
        }
    }

    setupUI() {
        this.authModal = document.getElementById('auth-modal');
        this.modalTitle = document.getElementById('auth-modal-title');
        this.loginForm = document.getElementById('login-form');
        this.signupForm = document.getElementById('signup-form');
        this.toggleLinks = document.querySelectorAll('[data-auth-toggle]');
        this.logoutButton = document.getElementById('logout-btn');

        if (this.loginForm) {
            this.loginForm.addEventListener('submit', async (event) => {
                event.preventDefault();
                const email = event.target.querySelector('input[name="email"]').value;
                const password = event.target.querySelector('input[name="password"]').value;
                await this.signIn(email, password);
            });
        }

        if (this.signupForm) {
            this.signupForm.addEventListener('submit', async (event) => {
                event.preventDefault();
                const displayName = event.target.querySelector('input[name="displayName"]').value;
                const email = event.target.querySelector('input[name="email"]').value;
                const password = event.target.querySelector('input[name="password"]').value;
                await this.signUp(displayName, email, password);
            });
        }

        if (this.toggleLinks) {
            this.toggleLinks.forEach((link) => {
                link.addEventListener('click', (event) => {
                    event.preventDefault();
                    const mode = link.dataset.authToggle;
                    this.showMode(mode === 'signup' ? 'signup' : 'login');
                });
            });
        }

        if (this.logoutButton) {
            this.logoutButton.addEventListener('click', () => {
                this.logout();
            });
        }
    }

    notifyApp() {
        if (this.appInstance && typeof this.appInstance.handleAuthStateChange === 'function') {
            this.appInstance.handleAuthStateChange(
                this.latestAuthState?.user || null,
                this.latestAuthState?.token || null
            );
        } else if (this.latestAuthState) {
            window.__pendingAuthState = this.latestAuthState;
        }
    }

    openAuthModal(mode = 'login') {
        this.showMode(mode);
        if (window.app && typeof window.app.openModal === 'function') {
            window.app.openModal('auth-modal');
        } else if (this.authModal) {
            this.authModal.classList.add('active');
            document.body.style.overflow = 'hidden';
        }
    }

    closeAuthModal() {
        if (window.app && typeof window.app.closeModal === 'function') {
            window.app.closeModal('auth-modal');
        } else if (this.authModal) {
            this.authModal.classList.remove('active');
            document.body.style.overflow = '';
        }
    }

    showMode(mode) {
        const isSignup = mode === 'signup';
        if (this.modalTitle) {
            this.modalTitle.textContent = isSignup ? 'Create Account' : 'Sign In';
        }
        if (this.loginForm) {
            this.loginForm.style.display = isSignup ? 'none' : 'block';
        }
        if (this.signupForm) {
            this.signupForm.style.display = isSignup ? 'block' : 'none';
        }
    }

    async signIn(email, password) {
        try {
            await signInWithEmailAndPassword(this.auth, email, password);
            this.closeAuthModal();
            this.toast('Welcome back!', 'success');
        } catch (error) {
            console.error('Sign-in failed:', error);
            this.toast(this.humanizeError(error), 'error');
        }
    }

    async signUp(displayName, email, password) {
        try {
            const credential = await createUserWithEmailAndPassword(this.auth, email, password);
            if (displayName) {
                try {
                    await updateProfile(credential.user, { displayName });
                } catch (profileError) {
                    console.warn('Unable to update display name:', profileError);
                }
            }
            this.closeAuthModal();
            this.toast('Account created successfully!', 'success');
        } catch (error) {
            console.error('Sign-up failed:', error);
            this.toast(this.humanizeError(error), 'error');
        }
    }

    async logout() {
        try {
            await signOut(this.auth);
            this.toast('Signed out successfully.', 'info');
        } catch (error) {
            console.error('Sign-out failed:', error);
            this.toast('Failed to sign out.', 'error');
        }
    }

    toast(message, type = 'info') {
        if (window.app && typeof window.app.showToast === 'function') {
            window.app.showToast(message, type);
        } else {
            console.log(`[${type}]`, message);
        }
    }

    humanizeError(error) {
        if (!error || !error.code) {
            return 'An unexpected error occurred. Please try again.';
        }
        switch (error.code) {
            case 'auth/email-already-in-use':
                return 'This email is already in use.';
            case 'auth/invalid-email':
                return 'Please enter a valid email address.';
            case 'auth/weak-password':
                return 'Password should be at least 6 characters long.';
            case 'auth/user-not-found':
            case 'auth/wrong-password':
                return 'Invalid email or password.';
            default:
                return 'Authentication failed. Please try again.';
        }
    }
}

const authManager = new AuthManager();
window.authManager = authManager;

export { authManager };
