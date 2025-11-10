import React, { useState } from 'react';
import apiClient from '../services/apiClient';
import { API_ENDPOINTS } from '../config/api';

const RecipeGeneratorPage = () => {
  const [ingredients, setIngredients] = useState([]);
  const [inputValue, setInputValue] = useState('');
  const [loading, setLoading] = useState(false);

  const handleAddIngredient = (e) => {
    if (e.key === 'Enter' && inputValue.trim()) {
      setIngredients([...ingredients, inputValue.trim()]);
      setInputValue('');
    }
  };

  const handleRemoveIngredient = (index) => {
    setIngredients(ingredients.filter((_, i) => i !== index));
  };

  const handleGenerateRecipes = async () => {
    try {
      setLoading(true);
      const data = await apiClient.post(API_ENDPOINTS.GENERATE_RECIPE, {
        ingredients,
        dietary_preferences: [],
        max_cooking_time: 60,
        servings: 2
      });
      console.log('Generated recipes:', data);
    } catch (error) {
      console.error('Error generating recipes:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <section id="recipe-generator-page" className="page">
      <div className="container">
        <div className="page-header">
          <h1>AI Recipe Generator</h1>
          <p>Create personalized recipes based on your ingredients and preferences</p>
        </div>

        <div className="generator-container">
          <div className="generator-form">
            <div className="form-section">
              <h3>Available Ingredients</h3>
              <div className="ingredients-input">
                <input 
                  type="text" 
                  placeholder="Type an ingredient and press Enter..."
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  onKeyPress={handleAddIngredient}
                />
                <div className="ingredients-tags">
                  {ingredients.map((ingredient, index) => (
                    <span key={index} className="tag">
                      {ingredient}
                      <button onClick={() => handleRemoveIngredient(index)}>×</button>
                    </span>
                  ))}
                </div>
              </div>
            </div>

            <button 
              className="btn btn-primary btn-large" 
              onClick={handleGenerateRecipes}
              disabled={loading || ingredients.length === 0}
            >
              <i className="fas fa-magic"></i>
              {loading ? 'Generating...' : 'Generate Recipes'}
            </button>
          </div>

          <div className="results-section" id="recipe-results">
            {/* Generated recipes will appear here */}
          </div>
        </div>
      </div>
    </section>
  );
};

export default RecipeGeneratorPage;
