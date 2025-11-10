# Recipe & Meal Planner - React Frontend

This is the React-based frontend for the Recipe & Meal Planner application, built with Vite.

## Features

- **React** - Modern React 18 with hooks
- **React Router** - Client-side routing
- **Firebase Authentication** - User authentication with Firebase
- **Axios** - HTTP client for API requests
- **Font Awesome** - Icon library
- **Vite** - Fast build tool and dev server

## Prerequisites

- Node.js 18+ and npm
- Backend server running on http://localhost:5000

## Getting Started

### 1. Install Dependencies

```bash
npm install
```

### 2. Environment Configuration

Create a `.env` file in the `frontend-react` directory (already created with defaults):

```env
VITE_API_BASE_URL=http://localhost:5000/api
```

### 3. Development Server

Run the development server with hot reload:

```bash
npm run dev
```

The app will be available at http://localhost:3000

### 4. Build for Production

Build the application for production:

```bash
npm run build
```

The build output will be in the `dist/` directory.

### 5. Preview Production Build

Preview the production build locally:

```bash
npm run preview
```

## Project Structure

```
frontend-react/
├── src/
│   ├── components/          # Reusable React components
│   │   └── Navbar.jsx       # Navigation bar
│   ├── pages/               # Page components
│   │   ├── HomePage.jsx
│   │   ├── YourFridgePage.jsx
│   │   ├── RecipeGeneratorPage.jsx
│   │   ├── MealPlannerPage.jsx
│   │   ├── NutritionTrackerPage.jsx
│   │   ├── GroceryListPage.jsx
│   │   └── LoginPage.jsx
│   ├── context/             # React Context providers
│   │   └── AuthContext.jsx  # Authentication context
│   ├── services/            # API services
│   │   └── apiClient.js     # HTTP client wrapper
│   ├── utils/               # Utility functions
│   │   ├── dateUtils.js
│   │   ├── storageUtils.js
│   │   └── validationUtils.js
│   ├── config/              # Configuration files
│   │   ├── api.js           # API endpoints
│   │   └── firebase.js      # Firebase config
│   ├── App.jsx              # Main app component
│   ├── main.jsx             # Entry point
│   ├── styles.css           # Global styles
│   └── components.css       # Component styles
├── public/                  # Static assets
├── dist/                    # Production build output
├── index.html               # HTML template
├── vite.config.js           # Vite configuration
└── package.json             # Dependencies and scripts
```

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## API Integration

The frontend communicates with the Flask backend via REST API. The API base URL is configured in `.env` and can be changed for different environments.

### API Endpoints Used

- `/api/health` - Health check
- `/api/recipes/generate-with-ai` - Generate AI recipes
- `/api/fridge/items` - Manage fridge items
- `/api/meal-plans` - Meal planning
- `/api/nutrition/logs` - Nutrition tracking
- `/api/grocery-lists` - Grocery lists
- `/api/users` - User management

## Firebase Configuration

Firebase is used for authentication. The configuration is in `src/config/firebase.js`. You may need to update this with your own Firebase project credentials.

## Deployment

The React app is built to static files and served by the Flask backend in production.

### Production Setup

1. Build the React app:
   ```bash
   npm run build
   ```

2. The Flask backend (in `backend/src/app.py`) is configured to serve the built files from `frontend-react/dist/`

3. Start the backend server, and it will serve both the API and the React app.

## Migration from Vanilla JS

This React app replaces the previous vanilla JavaScript frontend located in the `frontend/` directory. Key improvements:

- **Component-based architecture** - Better code organization and reusability
- **State management** - React Context for global state
- **Routing** - React Router for client-side navigation
- **Modern tooling** - Vite for fast development and optimized builds
- **Type safety potential** - Easy to add TypeScript in the future
- **Better developer experience** - Hot reload, error overlays, and debugging tools

## Troubleshooting

### CORS Issues

If you encounter CORS errors, make sure the backend's `.env` file includes your development URL:

```env
CORS_ORIGINS=http://localhost:3000,http://localhost:5000
```

### Firebase Authentication Issues

Make sure your Firebase project is properly configured and the credentials in `src/config/firebase.js` are correct.

### Build Issues

If you encounter build issues, try:

```bash
# Clean install
rm -rf node_modules package-lock.json
npm install
npm run build
```

## Contributing

When making changes:

1. Follow the existing code structure
2. Use functional components with hooks
3. Keep components small and focused
4. Add prop types or TypeScript types for better maintainability
5. Test your changes with both development and production builds

## License

MIT License - See LICENSE file for details
