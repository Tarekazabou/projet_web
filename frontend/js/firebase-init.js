import { initializeApp, getApps, getApp } from "https://www.gstatic.com/firebasejs/12.4.0/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/12.4.0/firebase-analytics.js";
import { firebaseConfig } from './config.js';

let app;
if (getApps().length) {
    app = getApp();
} else {
    app = initializeApp(firebaseConfig);
}

let analytics = null;
try {
    analytics = getAnalytics(app);
} catch (error) {
    console.warn('Firebase analytics not available in this environment:', error?.message || error);
}

export { app, analytics };
