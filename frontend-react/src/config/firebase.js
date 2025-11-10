// Firebase configuration
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyDS5lExXFmPc7JuX4u7x6KJKcwryjePPGc",
  authDomain: "mealy-41bf0.firebaseapp.com",
  projectId: "mealy-41bf0",
  storageBucket: "mealy-41bf0.appspot.com",
  messagingSenderId: "821075488273",
  appId: "1:821075488273:web:69007a1ad38bdf1c71cbb0",
  measurementId: "G-YN5H6CVV8B"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);

export default app;
