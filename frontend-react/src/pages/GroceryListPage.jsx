import React, { useState, useEffect } from 'react';
import apiClient from '../services/apiClient';
import { API_ENDPOINTS } from '../config/api';
import './GroceryListPage.css';

const GroceryListPage = () => {
  const [groceryItems, setGroceryItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [newItemName, setNewItemName] = useState('');
  const [newItemQuantity, setNewItemQuantity] = useState('1');
  const [newItemUnit, setNewItemUnit] = useState('pcs');
  const [newItemCategory, setNewItemCategory] = useState('Other');

  useEffect(() => {
    loadGroceryItems();
  }, []);

  const loadGroceryItems = async () => {
    try {
      setLoading(true);
      const response = await apiClient.get(API_ENDPOINTS.GROCERY_ITEMS);
      setGroceryItems(response.items || []);
    } catch (error) {
      console.error('Error loading grocery items:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAddItem = async (e) => {
    e.preventDefault();
    if (!newItemName.trim()) return;

    try {
      await apiClient.post(API_ENDPOINTS.GROCERY_ITEMS, {
        name: newItemName,
        quantity: newItemQuantity,
        unit: newItemUnit,
        category: newItemCategory,
        purchased: false,
      });

      setNewItemName('');
      setNewItemQuantity('1');
      await loadGroceryItems();
    } catch (error) {
      console.error('Error adding item:', error);
      alert('Erreur lors de l\'ajout de l\'article');
    }
  };

  const handleTogglePurchased = async (index, item) => {
    try {
      // If marking as purchased, add to fridge first
      if (!item.purchased) {
        console.log('📦 Adding item to fridge database:', item.name);
        
        // Add to fridge - this saves to Firestore database via backend API
        const fridgeResponse = await apiClient.post(API_ENDPOINTS.FRIDGE_ITEMS, {
          ingredientName: item.name,
          quantity: parseFloat(item.quantity) || 1,
          unit: item.unit || 'pcs',
          category: item.category || 'Autres',
          location: 'Main fridge',
          notes: 'Added from grocery list',
          expirationDate: null, // Can be set later by user
        });

        console.log('✅ Item saved to database:', fridgeResponse);

        // Show success message
        const toast = document.createElement('div');
        toast.className = 'toast-notification success';
        toast.innerHTML = `<i class="fas fa-check-circle"></i> ${item.name} ajouté au frigo et sauvegardé dans la base de données!`;
        document.body.appendChild(toast);
        setTimeout(() => toast.remove(), 3000);
      }

      // Toggle purchased status in grocery list
      console.log('🔄 Updating grocery list purchased status...');
      await apiClient.post(`/grocery/toggle-purchased/${index}`, {});
      
      // Reload the grocery list to reflect changes
      await loadGroceryItems();
      console.log('✅ Grocery list updated');
      
    } catch (error) {
      console.error('❌ Error toggling item:', error);
      alert('Erreur lors de la mise à jour: ' + (error.message || 'Unknown error'));
    }
  };

  const handleDeleteItem = async (index) => {
    try {
      await apiClient.delete(`${API_ENDPOINTS.GROCERY_ITEMS}/${index}`);
      await loadGroceryItems();
    } catch (error) {
      console.error('Error deleting item:', error);
      alert('Erreur lors de la suppression');
    }
  };

  const handleClearPurchased = async () => {
    if (!window.confirm('Supprimer tous les articles achetés ?')) return;

    try {
      await apiClient.post('/grocery/clear-purchased', {});
      await loadGroceryItems();
    } catch (error) {
      console.error('Error clearing purchased items:', error);
      alert('Erreur lors de la suppression');
    }
  };

  const purchasedItems = groceryItems.filter(item => item.purchased);
  const unpurchasedItems = groceryItems.filter(item => !item.purchased);

  return (
    <section id="grocery-list-page" className="page">
      <div className="container">
        <div className="page-header">
          <h1>🛒 Smart Grocery List</h1>
          <p>Manage your grocery list - checked items are added to your fridge automatically!</p>
        </div>

        <div className="grocery-container">
          {/* Add New Item Form */}
          <div className="add-item-card">
            <h3>📝 Add New Item</h3>
            <form onSubmit={handleAddItem} className="add-item-form">
              <div className="form-row">
                <input
                  type="text"
                  placeholder="Item name"
                  value={newItemName}
                  onChange={(e) => setNewItemName(e.target.value)}
                  className="item-input"
                  required
                />
                <input
                  type="text"
                  placeholder="Qty"
                  value={newItemQuantity}
                  onChange={(e) => setNewItemQuantity(e.target.value)}
                  className="qty-input"
                />
                <select
                  value={newItemUnit}
                  onChange={(e) => setNewItemUnit(e.target.value)}
                  className="unit-select"
                >
                  <option value="pcs">pcs</option>
                  <option value="kg">kg</option>
                  <option value="g">g</option>
                  <option value="L">L</option>
                  <option value="mL">mL</option>
                  <option value="cup">cup</option>
                </select>
                <select
                  value={newItemCategory}
                  onChange={(e) => setNewItemCategory(e.target.value)}
                  className="category-select"
                >
                  <option value="Fruits et légumes">Fruits et légumes</option>
                  <option value="Produits laitiers">Produits laitiers</option>
                  <option value="Viandes et fruits de mer">Viandes</option>
                  <option value="Garde-manger">Garde-manger</option>
                  <option value="Boissons">Boissons</option>
                  <option value="Other">Autres</option>
                </select>
                <button type="submit" className="btn btn-primary">
                  <i className="fas fa-plus"></i> Add
                </button>
              </div>
            </form>
          </div>

          {/* Stats Bar */}
          <div className="grocery-stats">
            <div className="stat-item">
              <span className="stat-value">{unpurchasedItems.length}</span>
              <span className="stat-label">To Buy</span>
            </div>
            <div className="stat-item">
              <span className="stat-value">{purchasedItems.length}</span>
              <span className="stat-label">Purchased</span>
            </div>
            <div className="stat-item">
              <span className="stat-value">{groceryItems.length}</span>
              <span className="stat-label">Total</span>
            </div>
          </div>

          {/* Grocery List */}
          <div className="grocery-list-container">
            {loading ? (
              <div className="loading-state">
                <i className="fas fa-spinner fa-spin"></i>
                <p>Loading grocery list...</p>
              </div>
            ) : groceryItems.length === 0 ? (
              <div className="empty-state">
                <i className="fas fa-shopping-basket"></i>
                <h3>Your grocery list is empty</h3>
                <p>Add items manually or generate from your meal plan</p>
              </div>
            ) : (
              <>
                {/* Unpurchased Items */}
                {unpurchasedItems.length > 0 && (
                  <div className="grocery-section">
                    <div className="section-header">
                      <h3>📋 To Buy</h3>
                      <span className="item-count">{unpurchasedItems.length} items</span>
                    </div>
                    <div className="grocery-items">
                      {unpurchasedItems.map((item, index) => (
                        <div key={index} className="grocery-item">
                          <div className="item-checkbox">
                            <input
                              type="checkbox"
                              checked={false}
                              onChange={() => handleTogglePurchased(
                                groceryItems.findIndex(i => i === item),
                                item
                              )}
                              id={`item-${index}`}
                            />
                            <label htmlFor={`item-${index}`}></label>
                          </div>
                          <div className="item-details">
                            <span className="item-name">{item.name}</span>
                            <span className="item-meta">
                              {item.quantity} {item.unit} • {item.category}
                            </span>
                          </div>
                          <button
                            className="btn-delete"
                            onClick={() => handleDeleteItem(
                              groceryItems.findIndex(i => i === item)
                            )}
                          >
                            <i className="fas fa-trash"></i>
                          </button>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Purchased Items */}
                {purchasedItems.length > 0 && (
                  <div className="grocery-section purchased-section">
                    <div className="section-header">
                      <h3>✅ Purchased (Added to Fridge)</h3>
                      <button
                        className="btn btn-sm btn-danger"
                        onClick={handleClearPurchased}
                      >
                        <i className="fas fa-trash"></i> Clear All
                      </button>
                    </div>
                    <div className="grocery-items">
                      {purchasedItems.map((item, index) => (
                        <div key={index} className="grocery-item purchased">
                          <div className="item-checkbox">
                            <input
                              type="checkbox"
                              checked={true}
                              onChange={() => handleTogglePurchased(
                                groceryItems.findIndex(i => i === item),
                                item
                              )}
                              id={`purchased-${index}`}
                            />
                            <label htmlFor={`purchased-${index}`}></label>
                          </div>
                          <div className="item-details">
                            <span className="item-name">{item.name}</span>
                            <span className="item-meta">
                              {item.quantity} {item.unit} • {item.category}
                            </span>
                          </div>
                          <button
                            className="btn-delete"
                            onClick={() => handleDeleteItem(
                              groceryItems.findIndex(i => i === item)
                            )}
                          >
                            <i className="fas fa-trash"></i>
                          </button>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      </div>
    </section>
  );
};

export default GroceryListPage;
