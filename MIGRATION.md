# Migration Guide: Vanilla JS to React

This document provides guidance for understanding the migration from the vanilla JavaScript frontend (`frontend/`) to the new React frontend (`frontend-react/`).

## Architecture Changes

### Before (Vanilla JS)
```
frontend/
├── index.html           # Single HTML file with all pages
├── css/
│   ├── styles.css       # Global styles
│   └── components.css   # Component styles
└── js/
    ├── main.js          # App initialization
    ├── auth.js          # Firebase auth
    ├── core/            # Core managers (Router, Modal, Toast, etc.)
    ├── services/        # API client
    ├── pages/           # Page controllers
    └── utils/           # Utility functions
```

### After (React)
```
frontend-react/
├── index.html           # HTML shell (minimal)
├── src/
│   ├── main.jsx         # React entry point
│   ├── App.jsx          # Main app with routing
│   ├── components/      # Reusable React components
│   ├── pages/           # Page components (React)
│   ├── context/         # React Context (state management)
│   ├── services/        # API client (adapted for React)
│   ├── utils/           # Utility functions (reused)
│   └── config/          # Configuration files
└── package.json         # Node dependencies
```

## Key Differences

### 1. Routing

**Before (Vanilla JS):**
```javascript
// Router.js - Manual DOM manipulation
class Router {
    navigate(pageName) {
        // Hide all pages
        document.querySelectorAll('.page').forEach(page => {
            page.classList.remove('active');
        });
        
        // Show selected page
        const page = document.getElementById(`${pageName}-page`);
        if (page) {
            page.classList.add('active');
        }
    }
}
```

**After (React):**
```jsx
// App.jsx - React Router
import { BrowserRouter, Routes, Route } from 'react-router-dom';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/your-fridge" element={<YourFridgePage />} />
        {/* ... more routes */}
      </Routes>
    </BrowserRouter>
  );
}
```

### 2. Authentication

**Before (Vanilla JS):**
```javascript
// auth.js - Global authManager
class AuthManager {
    constructor() {
        this.currentUser = null;
        this.init();
    }
    
    async login(email, password) {
        const result = await signInWithEmailAndPassword(auth, email, password);
        this.currentUser = result.user;
        this.updateUI();
    }
}

window.authManager = new AuthManager();
```

**After (React):**
```jsx
// AuthContext.jsx - React Context
export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, setCurrentUser);
    return unsubscribe;
  }, []);

  const login = async (email, password) => {
    return await signInWithEmailAndPassword(auth, email, password);
  };

  return (
    <AuthContext.Provider value={{ currentUser, login }}>
      {children}
    </AuthContext.Provider>
  );
};

// Usage in components
const { currentUser, login } = useAuth();
```

### 3. API Calls

**Before (Vanilla JS):**
```javascript
// In page controller
async loadIngredients() {
    try {
        const data = await window.apiClient.get('/fridge/items');
        this.updateIngredientsList(data);
    } catch (error) {
        window.toastManager.error('Failed to load ingredients');
    }
}
```

**After (React):**
```jsx
// In component
function YourFridgePage() {
  const [ingredients, setIngredients] = useState([]);

  useEffect(() => {
    const loadIngredients = async () => {
      try {
        const data = await apiClient.get('/fridge/items');
        setIngredients(data);
      } catch (error) {
        console.error('Failed to load ingredients:', error);
      }
    };
    
    loadIngredients();
  }, []);

  return (
    <div>
      {ingredients.map(item => <div key={item.id}>{item.name}</div>)}
    </div>
  );
}
```

### 4. State Management

**Before (Vanilla JS):**
- Global state in `window` object
- Manual DOM updates
- Event listeners for state changes

**After (React):**
- Component state with `useState`
- Global state with React Context
- Automatic re-renders on state changes

### 5. Page Structure

**Before (Vanilla JS):**
```html
<!-- All pages in single HTML file -->
<section id="home-page" class="page active">
    <!-- Home page content -->
</section>

<section id="your-fridge-page" class="page">
    <!-- Fridge page content -->
</section>
```

**After (React):**
```jsx
// Separate component files
// HomePage.jsx
export default function HomePage() {
  return (
    <section className="page active">
      {/* Home page content */}
    </section>
  );
}

// YourFridgePage.jsx
export default function YourFridgePage() {
  return (
    <section className="page">
      {/* Fridge page content */}
    </section>
  );
}
```

## Benefits of React Migration

### 1. **Component Reusability**
- Create reusable components once, use everywhere
- Better code organization and maintainability
- Example: `<Navbar />` used across all pages

### 2. **Declarative UI**
- UI automatically updates when state changes
- No manual DOM manipulation needed
- Easier to reason about UI state

### 3. **Better Developer Experience**
- Hot Module Replacement (HMR) - instant feedback
- Better debugging tools (React DevTools)
- Type safety (can add TypeScript easily)

### 4. **Modern Tooling**
- Vite for fast builds
- NPM ecosystem for libraries
- Easy integration with testing frameworks

### 5. **Performance**
- Virtual DOM for efficient updates
- Code splitting for faster initial load
- Built-in optimizations

## Migration Checklist

If you're working on features from the old frontend:

- [ ] Find equivalent component in `frontend-react/src/pages/`
- [ ] Convert vanilla JS to React hooks (`useState`, `useEffect`)
- [ ] Replace global state access with Context API
- [ ] Replace manual DOM updates with state changes
- [ ] Update API calls to use React patterns
- [ ] Test with React DevTools

## Common Patterns

### Pattern 1: Event Handlers

**Before:**
```javascript
document.getElementById('btn').addEventListener('click', () => {
    // handle click
});
```

**After:**
```jsx
<button onClick={() => {/* handle click */}}>Click Me</button>
```

### Pattern 2: Conditional Rendering

**Before:**
```javascript
if (loading) {
    element.innerHTML = '<p>Loading...</p>';
} else {
    element.innerHTML = '<p>Data loaded</p>';
}
```

**After:**
```jsx
{loading ? <p>Loading...</p> : <p>Data loaded</p>}
```

### Pattern 3: Lists

**Before:**
```javascript
const html = items.map(item => `<div>${item.name}</div>`).join('');
container.innerHTML = html;
```

**After:**
```jsx
{items.map(item => <div key={item.id}>{item.name}</div>)}
```

## Backwards Compatibility

The old vanilla JS frontend (`frontend/`) is still in the repository but is **deprecated**. All new development should use the React frontend (`frontend-react/`).

The Flask backend has been updated to serve the React build from `frontend-react/dist/`, so the old frontend will not be accessible in production.

## Need Help?

- Check the [React documentation](https://react.dev/)
- See `frontend-react/README.md` for setup instructions
- Look at existing components in `frontend-react/src/` for examples
- React DevTools browser extension for debugging

## Additional Resources

- [React Hooks Reference](https://react.dev/reference/react)
- [React Router Documentation](https://reactrouter.com/)
- [Vite Guide](https://vite.dev/guide/)
- [Firebase with React](https://firebase.google.com/docs/web/setup)
