# Mealy API Documentation

## Présentation des API (Rôles et Endpoints Principaux)

Cette documentation présente l'architecture de l'API RESTful de Mealy, incluant le système d'authentification, les rôles d'utilisateurs et les endpoints principaux.

---

## Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Authentification et Autorisation](#authentification-et-autorisation)
3. [Système de Rôles et Permissions](#système-de-rôles-et-permissions)
4. [Format des Réponses](#format-des-réponses)
5. [Endpoints Principaux](#endpoints-principaux)
   - [Utilisateurs](#utilisateurs)
   - [Recettes AI](#recettes-ai)
   - [Gestion du Frigo](#gestion-du-frigo)
   - [Planification de Repas](#planification-de-repas)
   - [Liste de Courses](#liste-de-courses)
   - [Nutrition](#nutrition)
   - [Dashboard](#dashboard)
   - [Feedback](#feedback)
   - [Scanner (Aliments & Reçus)](#scanner-aliments--reçus)
   - [Paramètres](#paramètres)
6. [Codes d'Erreur](#codes-derreur)

---

## Vue d'ensemble

### URL de Base
```
http://localhost:5000/api
```

### Architecture
L'API Mealy suit les principes RESTful et utilise:
- **Framework**: Flask 2.3+
- **Base de données**: Google Firestore
- **Authentification**: Firebase Authentication + JWT
- **IA**: Google Gemini pour la génération de recettes
- **Format**: JSON pour toutes les requêtes et réponses

---

## Authentification et Autorisation

### Méthodes d'Authentification

L'API supporte deux méthodes d'authentification:

#### 1. Firebase Authentication (Recommandé)
```http
Authorization: Bearer <firebase_id_token>
```

**Exemple:**
```bash
curl -X GET https://api.mealy.com/api/fridge/items \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtp..."
```

#### 2. User ID Header (Développement)
```http
X-User-Id: <user_id>
```

**Exemple:**
```bash
curl -X GET http://localhost:5000/api/fridge/items \
  -H "X-User-Id: demo_user_01"
```

### Mode Démo

Si aucune authentification n'est fournie, l'API utilise automatiquement un utilisateur démo (`demo_user_01`) pour faciliter les tests et le développement.

---

## Système de Rôles et Permissions

### Rôles Disponibles

| Rôle | Description | Permissions |
|------|-------------|-------------|
| **admin** | Administrateur complet | Toutes les opérations (lecture, écriture, suppression) sur toutes les ressources |
| **premium_user** | Utilisateur premium | Accès aux fonctionnalités IA avancées, génération illimitée de recettes |
| **user** | Utilisateur standard | Accès aux fonctionnalités de base (lecture, création de recettes simples) |

### Matrice de Permissions

#### Admin
```
✓ user:read, user:write, user:delete
✓ recipe:read, recipe:write, recipe:delete
✓ meal_plan:read, meal_plan:write, meal_plan:delete
✓ settings:read, settings:write
✓ analytics:read
```

#### Premium User
```
✓ user:read, user:write
✓ recipe:read, recipe:write
✓ meal_plan:read, meal_plan:write
✓ ai:generate, ai:advanced
```

#### User (Standard)
```
✓ user:read, user:write
✓ recipe:read
✓ meal_plan:read, meal_plan:write
✓ ai:generate
```

### Utilisation des Décorateurs de Sécurité

```python
# Requiert l'authentification
@require_auth()
def protected_endpoint():
    pass

# Requiert un rôle spécifique
@require_role('admin', 'premium_user')
def admin_endpoint():
    pass

# Vérifie une permission spécifique
@check_permission('recipe:write')
def create_recipe():
    pass
```

---

## Format des Réponses

### Réponse de Succès

```json
{
  "status": "success",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "data": {
    // Response payload
  },
  "message": "Operation completed successfully",
  "meta": {
    // Optional metadata (pagination, etc.)
  }
}
```

### Réponse d'Erreur

```json
{
  "status": "error",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "message": "Error description",
  "error_code": "ERROR_CODE",
  "details": {
    // Additional error information
  },
  "field_errors": {
    "field_name": ["Error message 1", "Error message 2"]
  }
}
```

### Codes HTTP Standards

| Code | Signification | Usage |
|------|---------------|-------|
| 200 | OK | Requête réussie |
| 201 | Created | Ressource créée avec succès |
| 204 | No Content | Opération réussie sans contenu de retour |
| 400 | Bad Request | Données de requête invalides |
| 401 | Unauthorized | Authentification requise |
| 403 | Forbidden | Permission refusée |
| 404 | Not Found | Ressource non trouvée |
| 422 | Validation Error | Erreurs de validation |
| 500 | Internal Error | Erreur serveur |
| 503 | Service Unavailable | Service temporairement indisponible |

---

## Endpoints Principaux

### Utilisateurs

Gestion des comptes utilisateurs, authentification et profils.

#### Créer un compte (Registration)
```http
POST /api/users/register
Content-Type: application/json
```

**Requête:**
```json
{
  "email": "user@example.com",
  "password": "secure_password123",
  "username": "john_doe"
}
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "id": "user_12345",
    "email": "user@example.com",
    "username": "john_doe",
    "createdAt": "2024-01-15T10:00:00.000Z"
  }
}
```

#### Se connecter (Login)
```http
POST /api/users/login
Content-Type: application/json
```

**Requête:**
```json
{
  "email": "user@example.com",
  "password": "secure_password123"
}
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "user_12345",
      "email": "user@example.com",
      "username": "john_doe"
    },
    "token": "jwt_token_here"
  }
}
```

#### Obtenir un utilisateur
```http
GET /api/users/{user_id}
X-User-Id: {user_id}
```

#### Mettre à jour un utilisateur
```http
PUT /api/users/{user_id}
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "displayName": "John Doe",
  "dietary_preferences": ["vegetarian", "gluten-free"],
  "allergies": ["nuts", "dairy"],
  "nutritionGoals": {
    "calories": 2000,
    "protein": 150,
    "carbs": 250,
    "fat": 65
  }
}
```

#### Mettre à jour les préférences
```http
PUT /api/users/{user_id}/preferences
Content-Type: application/json
```

---

### Recettes AI

Génération de recettes personnalisées avec Google Gemini AI.

#### Générer une recette avec IA (Complet)
```http
POST /api/recipes/generate-with-ai
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "ingredients": ["chicken", "tomatoes", "basil"],
  "dietary_preferences": ["healthy", "low-carb"],
  "max_cooking_time": 45,
  "servings": 4,
  "cuisine_type": "Italian",
  "meal_type": "dinner"
}
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "recipe": {
      "name": "Italian Herb Chicken",
      "description": "Delicious low-carb chicken with fresh tomatoes",
      "ingredients": [
        {
          "name": "chicken breast",
          "quantity": "500g",
          "unit": "g"
        }
      ],
      "instructions": [
        "Step 1: Prepare ingredients...",
        "Step 2: Cook chicken..."
      ],
      "prepTime": 15,
      "cookTime": 30,
      "servings": 4,
      "nutrition": {
        "calories": 350,
        "protein": 45,
        "carbs": 12,
        "fat": 15
      }
    }
  }
}
```

#### Générer à partir du texte
```http
POST /api/recipes/generate-from-text
Content-Type: application/json
```

**Requête:**
```json
{
  "query": "I want a quick healthy breakfast with eggs"
}
```

#### Générer à partir des ingrédients
```http
POST /api/recipes/generate-from-ingredients
Content-Type: application/json
```

**Requête:**
```json
{
  "ingredients": ["eggs", "spinach", "cheese"],
  "servings": 2
}
```

#### Générer à partir du frigo
```http
POST /api/recipes/generate-from-fridge
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "max_cooking_time": 30,
  "servings": 2,
  "meal_type": "lunch"
}
```

#### Générer plusieurs recettes
```http
POST /api/recipes/generate-multiple
Content-Type: application/json
```

**Requête:**
```json
{
  "count": 3,
  "ingredients": ["chicken"],
  "dietary_preferences": ["healthy"]
}
```

#### Lister les recettes
```http
GET /api/recipes/list?page=1&limit=20
X-User-Id: {user_id}
```

#### Obtenir une recette par ID
```http
GET /api/recipes/{recipe_id}
X-User-Id: {user_id}
```

#### Statut du service AI
```http
GET /api/recipes/status
```

---

### Gestion du Frigo

Gestion des ingrédients disponibles dans le réfrigérateur.

#### Obtenir tous les items du frigo
```http
GET /api/fridge/items?search=&freshness=all
X-User-Id: {user_id}
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "items": [
      {
        "id": "item_123",
        "name": "Chicken breast",
        "ingredientName": "Chicken breast",
        "quantity": 500,
        "unit": "g",
        "category": "Meat",
        "expiryDate": "2024-01-20",
        "freshness": "fresh"
      }
    ]
  }
}
```

#### Ajouter un item au frigo
```http
POST /api/fridge/items
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "ingredientName": "Tomatoes",
  "quantity": 6,
  "unit": "pieces",
  "category": "Vegetables",
  "expirationDate": "2024-01-25"
}
```

#### Mettre à jour un item
```http
PUT /api/fridge/items/{item_id}
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "quantity": 3,
  "expirationDate": "2024-01-26"
}
```

#### Supprimer un item
```http
DELETE /api/fridge/items/{item_id}
X-User-Id: {user_id}
```

#### Suggérer des recettes depuis le frigo
```http
POST /api/fridge/suggest-recipes
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "meal_type": "dinner",
  "servings": 4
}
```

#### Ajouter des items démo (développement)
```http
POST /api/fridge/seed-demo-items
X-User-Id: {user_id}
```

---

### Planification de Repas

Planification hebdomadaire des repas avec suggestions IA.

#### Créer un plan de repas
```http
POST /api/meal-plans/
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "planDate": "2024-01-15",
  "mealType": "lunch",
  "recipe": {
    "name": "Grilled Chicken Salad",
    "calories": 450,
    "ingredients": ["chicken", "lettuce", "tomatoes"]
  },
  "servings": 2,
  "notes": "Meal prep for Monday"
}
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "id": "plan_123",
    "planDate": "2024-01-15",
    "mealType": "lunch",
    "recipe": {
      "name": "Grilled Chicken Salad",
      "calories": 450
    },
    "servings": 2,
    "createdAt": "2024-01-15T08:00:00.000Z"
  }
}
```

#### Obtenir les plans de repas
```http
GET /api/meal-plans/?start_date=2024-01-15&end_date=2024-01-22
X-User-Id: {user_id}
```

#### Obtenir les plans de la semaine
```http
GET /api/meal-plans/week?start_date=2024-01-15
X-User-Id: {user_id}
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "plans": [
      {
        "id": "plan_123",
        "planDate": "2024-01-15",
        "mealType": "breakfast",
        "recipe": {
          "name": "Oatmeal with berries",
          "calories": 350
        }
      }
    ],
    "startDate": "2024-01-15",
    "endDate": "2024-01-21"
  }
}
```

#### Obtenir un plan spécifique
```http
GET /api/meal-plans/{plan_id}
X-User-Id: {user_id}
```

#### Mettre à jour un plan
```http
PUT /api/meal-plans/{plan_id}
Content-Type: application/json
X-User-Id: {user_id}
```

#### Supprimer un plan
```http
DELETE /api/meal-plans/{plan_id}
X-User-Id: {user_id}
```

#### Suggestions IA de repas
```http
POST /api/meal-plans/ai-suggest
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "mealType": "dinner",
  "servings": 4,
  "date": "2024-01-15"
}
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "suggestions": [
      {
        "name": "Teriyaki Chicken",
        "calories": 520,
        "prepTime": 30,
        "matchPercentage": 85,
        "ingredients": ["chicken", "soy sauce", "ginger"],
        "missingIngredients": ["mirin"]
      }
    ]
  }
}
```

#### Générer liste de courses depuis les plans
```http
POST /api/meal-plans/generate-grocery
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "startDate": "2024-01-15",
  "endDate": "2024-01-21"
}
```

---

### Liste de Courses

Gestion des listes de courses avec génération automatique depuis les plans de repas.

#### Obtenir les items de courses
```http
GET /api/grocery/items
X-User-Id: {user_id}
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "items": [
      {
        "name": "Chicken breast",
        "quantity": "1kg",
        "category": "Meat",
        "purchased": false
      }
    ],
    "progress": 35.5,
    "totalItems": 12,
    "purchasedCount": 4
  }
}
```

#### Ajouter un item
```http
POST /api/grocery/items
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "name": "Milk",
  "quantity": "1L",
  "category": "Dairy"
}
```

#### Mettre à jour un item
```http
PUT /api/grocery/items/{item_index}
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "name": "Milk",
  "quantity": "2L",
  "purchased": false
}
```

#### Supprimer un item
```http
DELETE /api/grocery/items/{item_index}
X-User-Id: {user_id}
```

#### Basculer l'état d'achat
```http
POST /api/grocery/toggle-purchased/{item_index}
X-User-Id: {user_id}
```

#### Effacer les items achetés
```http
POST /api/grocery/clear-purchased
X-User-Id: {user_id}
```

#### Créer depuis plan de repas
```http
POST /api/grocery/from-meal-plan
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "startDate": "2024-01-15",
  "endDate": "2024-01-21",
  "excludeFridgeItems": true
}
```

#### Obtenir toutes les listes
```http
GET /api/grocery/grocery-lists
X-User-Id: {user_id}
```

#### Supprimer une liste
```http
DELETE /api/grocery/grocery-lists/{list_id}
X-User-Id: {user_id}
```

#### Statistiques
```http
GET /api/grocery/stats
X-User-Id: {user_id}
```

---

### Nutrition

Suivi nutritionnel, analyse et objectifs.

#### Analyser la nutrition
```http
POST /api/nutrition/analyze
Content-Type: application/json
```

**Requête:**
```json
{
  "ingredients": [
    {
      "name": "chicken breast",
      "quantity": 200,
      "unit": "g"
    }
  ]
}
```

#### Rechercher des ingrédients
```http
GET /api/nutrition/ingredients/search?q=chicken&limit=10
```

#### Obtenir nutrition d'un ingrédient
```http
GET /api/nutrition/ingredients/{ingredient_id}
```

#### Obtenir les objectifs nutritionnels
```http
GET /api/nutrition/goals
X-User-Id: {user_id}
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "calories": 2000,
    "protein": 150,
    "carbs": 250,
    "fat": 65,
    "fiber": 25,
    "water": 8
  }
}
```

#### Définir les objectifs nutritionnels
```http
POST /api/nutrition/goals
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "calories": 2200,
  "protein": 160,
  "carbs": 280,
  "fat": 70,
  "fiber": 30,
  "water": 10
}
```

#### Obtenir nutrition quotidienne
```http
GET /api/nutrition/daily/{date}
X-User-Id: {user_id}
```

**Exemple:**
```http
GET /api/nutrition/daily/2024-01-15
```

#### Enregistrer un repas
```http
POST /api/nutrition/log-meal
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "date": "2024-01-15",
  "mealType": "lunch",
  "name": "Grilled Chicken Salad",
  "calories": 450,
  "protein": 45,
  "carbs": 20,
  "fat": 18
}
```

#### Supprimer un repas enregistré
```http
DELETE /api/nutrition/meals/{meal_id}
X-User-Id: {user_id}
```

#### Enregistrer consommation d'eau
```http
POST /api/nutrition/water-intake
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "date": "2024-01-15",
  "amount": 2.5
}
```

#### Tendance hebdomadaire
```http
GET /api/nutrition/weekly-trend?start_date=2024-01-15
X-User-Id: {user_id}
```

---

### Dashboard

Vue d'ensemble et statistiques de l'application.

#### Obtenir les statistiques
```http
GET /api/dashboard/stats
X-User-Id: {user_id}
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "totalRecipes": 45,
    "mealPlansThisWeek": 12,
    "fridgeItems": 23,
    "nutritionProgress": {
      "calories": 85,
      "protein": 92
    }
  }
}
```

#### Obtenir les actions rapides
```http
GET /api/dashboard/quick-actions
X-User-Id: {user_id}
```

#### Obtenir les conseils nutritionnels
```http
GET /api/dashboard/nutrition-tips
X-User-Id: {user_id}
```

#### Obtenir l'activité récente
```http
GET /api/dashboard/recent-activity
X-User-Id: {user_id}
```

---

### Feedback

Système de retour d'expérience utilisateur.

#### Soumettre un feedback
```http
POST /api/feedback/
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "recipeId": "recipe_123",
  "rating": 5,
  "comment": "Delicious recipe, very easy to follow!",
  "category": "recipe"
}
```

#### Obtenir feedback d'une recette
```http
GET /api/feedback/recipe/{recipe_id}
```

#### Obtenir feedback d'un utilisateur
```http
GET /api/feedback/user/{user_id}
X-User-Id: {user_id}
```

#### Supprimer un feedback
```http
DELETE /api/feedback/{feedback_id}
X-User-Id: {user_id}
```

---

### Scanner (Aliments & Reçus)

Reconnaissance visuelle d'aliments et de reçus avec IA.

#### Scanner un aliment
```http
POST /api/food-scanner/scan
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "image": "base64_encoded_image_data"
}
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "foodItems": [
      {
        "name": "Apple",
        "confidence": 0.95,
        "nutrition": {
          "calories": 95,
          "carbs": 25
        }
      }
    ]
  }
}
```

#### Enregistrer un aliment scanné
```http
POST /api/food-scanner/log
Content-Type: application/json
X-User-Id: {user_id}
```

#### Historique des scans
```http
GET /api/food-scanner/history
X-User-Id: {user_id}
```

#### Scanner un reçu
```http
POST /api/receipt-scanner/scan
Content-Type: application/json
X-User-Id: {user_id}
```

**Requête:**
```json
{
  "image": "base64_encoded_image_data"
}
```

#### Tester la connexion Ollama
```http
GET /api/receipt-scanner/test-connection
```

---

### Paramètres

Configuration de l'application et des clés API.

#### Tester la clé Gemini
```http
POST /api/settings/gemini-api-key/test
Content-Type: application/json
```

**Requête:**
```json
{
  "apiKey": "your_gemini_api_key"
}
```

#### Sauvegarder la clé Gemini
```http
POST /api/settings/gemini-api-key/save
Content-Type: application/json
```

**Requête:**
```json
{
  "apiKey": "your_gemini_api_key"
}
```

#### Obtenir le statut Gemini
```http
GET /api/settings/gemini-api-key/status
```

#### Supprimer la clé Gemini
```http
DELETE /api/settings/gemini-api-key/remove
```

---

## Codes d'Erreur

### Codes d'Erreur Courants

| Code | Description | Action Recommandée |
|------|-------------|-------------------|
| `UNAUTHORIZED` | Authentification requise | Fournir un token valide |
| `FORBIDDEN` | Permission refusée | Vérifier les droits d'accès |
| `RESOURCE_NOT_FOUND` | Ressource non trouvée | Vérifier l'ID de la ressource |
| `VALIDATION_ERROR` | Erreur de validation | Corriger les données d'entrée |
| `INTERNAL_ERROR` | Erreur serveur | Réessayer ou contacter le support |
| `AI_SERVICE_UNAVAILABLE` | Service IA indisponible | Vérifier la configuration de l'API Gemini |

### Exemples de Réponses d'Erreur

#### 401 Unauthorized
```json
{
  "status": "error",
  "message": "Authentication required. Please log in.",
  "error_code": "UNAUTHORIZED",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

#### 403 Forbidden
```json
{
  "status": "error",
  "message": "Access denied. Required role(s): admin, premium_user",
  "error_code": "FORBIDDEN",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

#### 404 Not Found
```json
{
  "status": "error",
  "message": "Recipe not found (ID: recipe_123)",
  "error_code": "RESOURCE_NOT_FOUND",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

#### 422 Validation Error
```json
{
  "status": "error",
  "message": "Validation failed",
  "error_code": "VALIDATION_ERROR",
  "field_errors": {
    "email": ["Email is required", "Email format is invalid"],
    "password": ["Password must be at least 6 characters"]
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

#### 500 Internal Server Error
```json
{
  "status": "error",
  "message": "Internal server error",
  "error_code": "INTERNAL_ERROR",
  "details": {
    "error_id": "err_abc123xyz"
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

---

## Health Check

### Vérifier l'état de l'API
```http
GET /api/health
```

**Réponse:**
```json
{
  "status": "success",
  "data": {
    "service": "Mealy API",
    "version": "3.0",
    "status": "healthy",
    "timestamp": "2024-01-15T10:30:00.000Z",
    "services": {
      "firebase": "connected",
      "gemini_ai": "available"
    }
  }
}
```

---

## Bonnes Pratiques

### 1. Gestion des Erreurs
- Toujours vérifier le champ `status` dans la réponse
- Utiliser les `error_code` pour un traitement programmatique des erreurs
- Logger les `error_id` pour faciliter le débogage

### 2. Performance
- Utiliser la pagination pour les listes volumineuses
- Mettre en cache les réponses fréquemment utilisées
- Limiter le nombre de requêtes par seconde

### 3. Sécurité
- Ne jamais exposer les tokens dans les URLs
- Utiliser HTTPS en production
- Renouveler régulièrement les tokens Firebase
- Ne pas stocker les clés API côté client

### 4. Développement
- Utiliser l'utilisateur démo pour les tests
- Activer les logs pour le débogage
- Tester avec différents rôles d'utilisateurs

---

## Support

Pour toute question ou problème:
- 📧 Email: support@mealy.com
- 🐛 Issues: [GitHub Issues](https://github.com/Tarekazabou/projet_web/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/Tarekazabou/projet_web/discussions)

---

**Documentation générée le:** 2024-01-15  
**Version de l'API:** 3.0  
**Dernière mise à jour:** 2024-01-15
