import React from 'react';
import { useNavigate } from 'react-router-dom';
import './HomePage.css';

const HomePage = () => {
  const navigate = useNavigate();

  return (
    <div id="home-page" className="page active">
      {/* Hero Section */}
      <div className="hero-section">
        <div className="hero-content">
          <h1 className="hero-title">AI-Powered Recipe & Meal Planning</h1>
          <p className="hero-subtitle">
            Discover personalized recipes, create balanced meal plans, and streamline your grocery shopping 
            with our intelligent cooking companion designed for health-conscious individuals.
          </p>
          <div className="hero-actions">
            <button 
              className="btn btn-primary btn-large" 
              onClick={() => navigate('/recipe-generator')}
            >
              <i className="fas fa-magic"></i>
              Start Cooking
            </button>
            <button 
              className="btn btn-outline btn-large" 
              onClick={() => navigate('/recipe-generator')}
            >
              <i className="fas fa-search"></i>
              Explore Recipes
            </button>
          </div>
        </div>
        <div className="hero-image">
          <div className="recipe-preview-card">
            <div className="card-image-placeholder">
              <i className="fas fa-camera"></i>
            </div>
            <h3>Quinoa Veggie Bowl</h3>
            <div className="recipe-tags">
              <span className="tag tag-vegan">Vegan</span>
              <span className="tag tag-healthy">Healthy</span>
            </div>
            <div className="recipe-stats">
              <span><i className="fas fa-clock"></i> 25 min</span>
              <span><i className="fas fa-users"></i> 2 servings</span>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="features-section">
        <div className="container">
          <h2 className="section-title">Everything You Need for Healthy Cooking</h2>
          <div className="features-grid">
            <div className="feature-card">
              <div className="feature-icon">
                <i className="fas fa-robot"></i>
              </div>
              <h3>AI Recipe Generation</h3>
              <p>Get personalized recipes based on your available ingredients, dietary preferences, and nutritional goals.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">
                <i className="fas fa-calendar-alt"></i>
              </div>
              <h3>Smart Meal Planning</h3>
              <p>Create balanced weekly meal plans with visual timelines and automatic nutritional analysis.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">
                <i className="fas fa-chart-line"></i>
              </div>
              <h3>Nutrition Tracking</h3>
              <p>Monitor your daily nutrition intake with detailed breakdowns and progress towards your health goals.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">
                <i className="fas fa-shopping-cart"></i>
              </div>
              <h3>Grocery Integration</h3>
              <p>Generate smart grocery lists and integrate with online stores for seamless shopping experiences.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">
                <i className="fas fa-heart"></i>
              </div>
              <h3>Dietary Preferences</h3>
              <p>Support for all dietary needs including vegan, keto, gluten-free, and custom restrictions.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon">
                <i className="fas fa-mobile-alt"></i>
              </div>
              <h3>AR Recipe Guides</h3>
              <p>Optional augmented reality cooking guidance for step-by-step visual assistance in your kitchen.</p>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="stats-section">
        <div className="container">
          <div className="stats-grid">
            <div className="stat-item">
              <div className="stat-number">1,247</div>
              <div className="stat-label">Recipes Available</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">3,892</div>
              <div className="stat-label">Meal Plans Created</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">12,567</div>
              <div className="stat-label">Users Helped</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">98%</div>
              <div className="stat-label">Satisfaction Rate</div>
            </div>
          </div>
        </div>
      </div>

      {/* Popular Recipes */}
      <div className="popular-recipes-section">
        <div className="container">
          <div className="section-header">
            <h2 className="section-title">Popular Recipes</h2>
            <button className="btn btn-outline" onClick={() => navigate('/recipe-generator')}>
              View All
            </button>
          </div>
          <div className="recipes-grid" id="popular-recipes-grid">
            {/* Popular recipes will be loaded here dynamically */}
          </div>
        </div>
      </div>
    </div>
  );
};

export default HomePage;
