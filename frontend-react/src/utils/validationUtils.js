// Validation utility functions
export const validationUtils = {
  isValidEmail: (email) => {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  },

  isValidPassword: (password) => {
    return password && password.length >= 6;
  },

  isValidIngredient: (ingredient) => {
    return ingredient && ingredient.trim().length > 0;
  },

  sanitizeInput: (input) => {
    if (!input) return '';
    return input.trim().replace(/[<>]/g, '');
  },

  validateRequiredFields: (data, fields) => {
    const errors = {};
    fields.forEach(field => {
      if (!data[field] || data[field].trim() === '') {
        errors[field] = `${field} is required`;
      }
    });
    return errors;
  }
};
