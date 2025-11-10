import React from 'react';

const GroceryListPage = () => {
  return (
    <section id="grocery-list-page" className="page">
      <div className="container">
        <div className="page-header">
          <h1>Smart Grocery List</h1>
          <p>Generate and manage grocery lists with store integrations</p>
        </div>

        <div className="grocery-container">
          <div className="grocery-controls">
            <div className="generation-options">
              <button className="btn btn-primary">
                <i className="fas fa-calendar"></i>
                From Meal Plan
              </button>
              <button className="btn btn-outline">
                <i className="fas fa-utensils"></i>
                From Recipes
              </button>
              <button className="btn btn-outline">
                <i className="fas fa-edit"></i>
                Manual List
              </button>
            </div>
            <div className="export-options">
              <button className="btn btn-success">
                <i className="fas fa-file-pdf"></i>
                Export PDF
              </button>
              <button className="btn btn-info">
                <i className="fas fa-shopping-cart"></i>
                Store Integration
              </button>
            </div>
          </div>

          <div className="grocery-list-container" id="grocery-list-container">
            {/* Grocery list will be displayed here */}
          </div>
        </div>
      </div>
    </section>
  );
};

export default GroceryListPage;
