import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import Navbar from './components/Navbar';
import HomePage from './pages/HomePage';
import YourFridgePage from './pages/YourFridgePage';
import RecipeGeneratorPage from './pages/RecipeGeneratorPage';
import MealPlannerPage from './pages/MealPlannerPage';
import NutritionTrackerPage from './pages/NutritionTrackerPage';
import GroceryListPage from './pages/GroceryListPage';
import LoginPage from './pages/LoginPage';
import './styles.css';
import './components.css';
import './App.css';

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="app">
          <Navbar />
          <main className="main-content">
            <Routes>
              <Route path="/" element={<HomePage />} />
              <Route path="/your-fridge" element={<YourFridgePage />} />
              <Route path="/recipe-generator" element={<RecipeGeneratorPage />} />
              <Route path="/meal-planner" element={<MealPlannerPage />} />
              <Route path="/nutrition-tracker" element={<NutritionTrackerPage />} />
              <Route path="/grocery-list" element={<GroceryListPage />} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </main>
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
