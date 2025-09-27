# Personalized Recipe and Meal Planning App

A comprehensive web application for personalized recipe generation, meal planning, nutrition tracking, and grocery list management with AI-powered recommendations.

## Features

### 🍳 AI-Powered Recipe Generation
- Smart ingredient-based recipe matching
- Dietary preference filtering (vegan, keto, gluten-free, etc.)
- Cooking time and difficulty customization
- Nutritional analysis integration
- Recipe relevance scoring

### 📅 Intelligent Meal Planning
- Weekly meal plan generation
- Drag-and-drop meal scheduling
- Automatic nutritional balance
- Meal plan templates and presets
- Export and sharing capabilities

### 📊 Nutrition Tracking
- Daily nutrition monitoring
- Macro and micronutrient analysis
- Goal setting and progress tracking
- Water intake logging
- USDA FoodData Central integration

### 🛒 Smart Grocery Lists
- Auto-generation from meal plans
- Category-based organization
- Price estimation
- Store integration (Instacart, Amazon Fresh)
- Sharing and collaboration features

## Technology Stack

### Backend
- **Framework**: Flask 2.3.3
- **Database**: MongoDB with PyMongo
- **APIs**: USDA FoodData Central API
- **AI/ML**: Custom recipe matching algorithms
- **Authentication**: Session-based user management

### Frontend
- **HTML5**: Semantic markup with accessibility features
- **CSS3**: Modern styling with CSS Grid, Flexbox, and animations
- **JavaScript**: Vanilla ES6+ with modular architecture
- **UI Components**: Custom component library
- **Responsive Design**: Mobile-first approach

## Project Structure

```
recipe_meal_planner/
├── app.py                          # Flask application entry point
├── backend/
│   ├── models/
│   │   └── models.py              # MongoDB data models
│   ├── routes/
│   │   ├── recipes.py             # Recipe API endpoints
│   │   ├── meal_plans.py          # Meal planning endpoints
│   │   ├── nutrition.py           # Nutrition tracking endpoints
│   │   ├── grocery.py             # Grocery list endpoints
│   │   ├── feedback.py            # User feedback endpoints
│   │   └── users.py               # User management endpoints
│   └── utils/
│       ├── recipe_generator.py    # AI recipe matching engine
│       ├── nutrition_calculator.py # Nutrition analysis system
│       └── db_init.py             # Database initialization
├── frontend/
│   ├── index.html                 # Main application interface
│   ├── css/
│   │   ├── styles.css             # Core styles and variables
│   │   └── components.css         # UI component styles
│   └── js/
│       ├── app.js                 # Main application controller
│       ├── recipe-generator.js    # Recipe generation module
│       ├── meal-planner.js        # Meal planning module
│       ├── nutrition-tracker.js   # Nutrition tracking module
│       └── grocery-list.js        # Grocery list management
├── requirements.txt               # Python dependencies
├── .env                          # Environment configuration
└── README.md                     # Project documentation
```

## Installation & Setup

### Prerequisites
- Python 3.8+
- MongoDB 4.4+
- Node.js 14+ (for development tools)

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd recipe_meal_planner
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Initialize database**
   ```bash
   python -c "from backend.utils.db_init import init_database; init_database()"
   ```

6. **Run the application**
   ```bash
   python app.py
   ```

### Frontend Setup

The frontend is served by Flask and requires no additional build step. Simply ensure all JavaScript modules are properly linked in `index.html`.

### Environment Variables

Create a `.env` file with the following configuration:

```env
# Flask Configuration
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=your-secret-key-here

# Database Configuration
MONGODB_URI=mongodb://localhost:27017/recipe_meal_planner

# API Keys
USDA_API_KEY=your-usda-api-key
INSTACART_API_KEY=your-instacart-api-key
AMAZON_API_KEY=your-amazon-api-key

# Server Configuration
PORT=5000
HOST=localhost
```

## API Documentation

### Recipe Endpoints
- `GET /api/recipes/search` - Search recipes with filters
- `POST /api/recipes/generate` - Generate personalized recipes
- `GET /api/recipes/categories` - Get dietary categories
- `GET /api/recipes/recommended` - Get recommended recipes

### Meal Planning Endpoints
- `GET /api/meal-plans` - Get meal plans by date range
- `POST /api/meal-plans` - Create new meal plan
- `POST /api/meal-plans/generate` - Auto-generate meal plan

### Nutrition Endpoints
- `GET /api/nutrition/daily/{date}` - Get daily nutrition data
- `POST /api/nutrition/log-meal` - Log meal entry
- `GET /api/nutrition/goals` - Get nutrition goals
- `POST /api/nutrition/goals` - Set nutrition goals

### Grocery List Endpoints
- `GET /api/grocery-lists` - Get all grocery lists
- `POST /api/grocery-lists` - Create new grocery list
- `POST /api/grocery-lists/generate-from-meal-plan` - Generate from meal plan

## Features in Detail

### Recipe Generation Algorithm
- **Ingredient Matching**: Fuzzy matching with ingredient substitutions
- **Dietary Filtering**: Multi-tag dietary preference system
- **Nutritional Scoring**: Balance-based recipe ranking
- **Personalization**: User preference learning over time

### Meal Planning Intelligence
- **Nutritional Balance**: Automatic macro/micronutrient optimization
- **Variety Optimization**: Ensures diverse meal selections
- **Preference Learning**: Adapts to user choices and ratings
- **Schedule Integration**: Considers cooking time and complexity

### Nutrition Analysis
- **USDA Integration**: Real-time nutritional data lookup
- **Goal Tracking**: Customizable nutrition targets
- **Progress Analytics**: Daily, weekly, monthly progress tracking
- **Smart Logging**: Quick meal entry with search and suggestions

### Grocery Integration
- **Smart Categorization**: Automatic ingredient categorization
- **Price Estimation**: Basic price estimation system
- **Store APIs**: Integration with major grocery delivery services
- **List Optimization**: Efficient shopping list organization

## Development

### Code Organization
- **Modular Architecture**: Separate concerns with dedicated modules
- **Component System**: Reusable UI components
- **API-First Design**: Clean separation of frontend and backend
- **Error Handling**: Comprehensive error management and user feedback

### Testing
```bash
# Run backend tests
python -m pytest tests/

# Run frontend tests (if applicable)
npm test
```

### Contributing
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Deployment

### Production Setup
1. Set `FLASK_ENV=production` in environment
2. Configure production database
3. Set up reverse proxy (nginx recommended)
4. Enable HTTPS with SSL certificates
5. Configure monitoring and logging

### Docker Deployment
```bash
# Build and run with Docker
docker build -t recipe-meal-planner .
docker run -p 5000:5000 recipe-meal-planner
```

## Future Enhancements

### Phase 1 (Near-term)
- [ ] Mobile app (React Native/Flutter)
- [ ] Recipe image recognition
- [ ] Social features (sharing, following)
- [ ] Advanced nutrition insights

### Phase 2 (Medium-term)
- [ ] AR grocery shopping features
- [ ] Voice assistant integration
- [ ] Machine learning recipe recommendations
- [ ] Kitchen appliance integration

### Phase 3 (Long-term)
- [ ] AI nutrition coaching
- [ ] Meal kit delivery partnerships
- [ ] Restaurant integration
- [ ] Health tracker integrations

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please contact [support@recipemealplanner.com](mailto:support@recipemealplanner.com) or create an issue in the GitHub repository.

## Acknowledgments

- USDA FoodData Central for nutritional data
- FontAwesome for icons
- MongoDB Atlas for database hosting
- All contributors and beta testers

---

**Built with ❤️ for healthier eating and smarter meal planning**