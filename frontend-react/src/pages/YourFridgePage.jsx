import React, { useState, useEffect } from 'react';
import apiClient from '../services/apiClient';
import { API_ENDPOINTS } from '../config/api';

const YourFridgePage = () => {
  const [ingredients, setIngredients] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadIngredients();
  }, []);

  const loadIngredients = async () => {
    try {
      setLoading(true);
      const data = await apiClient.get(API_ENDPOINTS.FRIDGE_ITEMS);
      setIngredients(data || []);
    } catch (error) {
      console.error('Error loading ingredients:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <section id="your-fridge-page" className="page">
      <div className="container">
        <div className="page-header">
          <h1><i className="fas fa-refrigerator"></i> Your Fridge</h1>
          <p>Track your ingredients and get recipe suggestions based on what you have at home</p>
        </div>

        <div className="fridge-container">
          <div className="fridge-actions">
            <div className="action-buttons">
              <button className="btn btn-primary">
                <i className="fas fa-plus"></i>
                Add Ingredient
              </button>
              <button className="btn btn-outline">
                <i className="fas fa-database"></i>
                Add Demo Items
              </button>
              <button className="btn btn-secondary">
                <i className="fas fa-magic"></i>
                Suggest Recipes
              </button>
            </div>
            
            <div className="fridge-stats">
              <div className="stat-card">
                <div className="stat-value">{ingredients.length}</div>
                <div className="stat-label">Total Items</div>
              </div>
            </div>
          </div>

          <div className="fridge-inventory" id="fridge-inventory">
            {loading ? (
              <p>Loading ingredients...</p>
            ) : ingredients.length === 0 ? (
              <div className="empty-fridge">
                <div className="empty-fridge-icon">
                  <i className="fas fa-refrigerator"></i>
                </div>
                <h3>Your fridge is empty!</h3>
                <p>Start adding ingredients to get personalized recipe suggestions</p>
                <button className="btn btn-primary">
                  <i className="fas fa-plus"></i>
                  Add Your First Ingredient
                </button>
              </div>
            ) : (
              <div className="ingredients-list">
                {ingredients.map((ingredient, index) => (
                  <div key={index} className="ingredient-item">
                    <span>{ingredient.name}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </section>
  );
};

export default YourFridgePage;
