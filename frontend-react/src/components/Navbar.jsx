import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './Navbar.css';

const Navbar = () => {
  const { currentUser, logout } = useAuth();
  const location = useLocation();

  const isActive = (path) => location.pathname === path;

  const handleLogout = async () => {
    try {
      await logout();
    } catch (error) {
      console.error('Logout error:', error);
    }
  };

  return (
    <nav className="navbar">
      <div className="nav-container">
        <div className="nav-brand">
          <i className="fas fa-utensils"></i>
          <span>Recipe Planner</span>
        </div>
        
        <ul className="nav-menu">
          <li className="nav-item">
            <Link to="/" className={`nav-link ${isActive('/') ? 'active' : ''}`}>
              Home
            </Link>
          </li>
          <li className="nav-item">
            <Link to="/your-fridge" className={`nav-link ${isActive('/your-fridge') ? 'active' : ''}`}>
              Your Fridge
            </Link>
          </li>
          <li className="nav-item">
            <Link to="/recipe-generator" className={`nav-link ${isActive('/recipe-generator') ? 'active' : ''}`}>
              Recipe Generator
            </Link>
          </li>
          <li className="nav-item">
            <Link to="/meal-planner" className={`nav-link ${isActive('/meal-planner') ? 'active' : ''}`}>
              Meal Planner
            </Link>
          </li>
          <li className="nav-item">
            <Link to="/nutrition-tracker" className={`nav-link ${isActive('/nutrition-tracker') ? 'active' : ''}`}>
              Nutrition
            </Link>
          </li>
          <li className="nav-item">
            <Link to="/grocery-list" className={`nav-link ${isActive('/grocery-list') ? 'active' : ''}`}>
              Grocery List
            </Link>
          </li>
        </ul>
        
        <div className="nav-actions">
          <button className="btn btn-outline" title="Configure AI">
            <i className="fas fa-robot"></i>
          </button>
          <button className="btn btn-outline">
            <i className="fas fa-cog"></i>
          </button>
          {currentUser ? (
            <>
              <button className="btn btn-primary">
                <i className="fas fa-user"></i>
                <span className="nav-user-label">{currentUser.displayName || currentUser.email}</span>
              </button>
              <button className="btn btn-outline" onClick={handleLogout} title="Sign out">
                <i className="fas fa-sign-out-alt"></i>
              </button>
            </>
          ) : (
            <Link to="/login" className="btn btn-primary">
              <i className="fas fa-user"></i>
              <span className="nav-user-label">Sign In</span>
            </Link>
          )}
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
