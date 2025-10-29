# Mealy: Your Personal AI-Powered Recipe and Meal Planner

Mealy is a smart, web-based application designed to simplify your culinary life. From generating new recipe ideas to planning your weekly meals and tracking your nutritional intake, Mealy is your all-in-one kitchen assistant. This project uses a Python Flask backend, a modern JavaScript frontend, and is powered by Google's Firebase and DataConnect for a robust and scalable infrastructure.

## Project Structure

The project has been organized into three main directories to ensure a clean separation of concerns between the backend, frontend, and Firebase services.

```
/
├── backend/            # The Python Flask application
│   ├── src/            # Core application source code (app.py)
│   ├── models/         # Python data models
│   ├── routes/         # API endpoint definitions
│   ├── utils/          # Helper scripts and utilities (Firebase connection, auth)
│   ├── tests/          # Backend tests
│   ├── .env            # Environment variables for the backend
│   └── requirements.txt # Python dependencies
│
├── frontend/           # All frontend code
│   ├── css/            # CSS stylesheets
│   ├── js/             # JavaScript files for app logic
│   └── index.html      # Main HTML file
│
├── firebase/           # Firebase and Node.js services
│   ├── dataconnect/    # DataConnect schema and queries
│   ├── functions/      # Cloud Functions for Firebase
│   ├── firestore.rules # Security rules for Firestore
│   └── package.json    # Node.js dependencies
│
└── README.md           # This file
```

## Features

- **AI Recipe Generator**: Get creative in the kitchen with new recipes based on your preferences.
- **Weekly Meal Planner**: Organize your meals for the week ahead.
- **Nutritional Analysis**: Keep track of calories, macros, and other nutritional information.
- **Smart Grocery List**: Automatically generate a shopping list from your meal plan.
- **Fridge Inventory**: Manage the ingredients you currently have to reduce food waste.

## Tech Stack

- **Backend**: Python, Flask
- **Frontend**: HTML, CSS, Vanilla JavaScript
- **Database**: Google Firestore
- **Services**: Firebase DataConnect, Firebase Authentication, Google Cloud

## Setup and Installation

To get the application running locally, follow these steps.

### 1. Prerequisites

- [Python 3.10+](https://www.python.org/downloads/)
- [Node.js and npm](https://nodejs.org/en/download/)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

### 2. Backend Setup (Python)

Navigate to the backend directory and install the required Python packages.

```bash
cd backend
pip install -r requirements.txt
```

### 3. Firebase Services Setup (Node.js)

Navigate to the firebase directory and install the Node.js dependencies.

```bash
cd firebase
npm install
```

### 4. Google Cloud Authentication

To allow the application to connect to your Google Cloud and Firebase services, you need to authenticate your local machine.

```bash
gcloud auth application-default login
```

This command will open a browser window for you to log in with your Google account.

## Running the Application

The application is run by starting the Flask backend server, which also serves the frontend files.

1.  **Set Environment Variables**:
    Make sure you have a `.env` file in the `backend` directory with any necessary configuration, such as your Firebase Project ID.

2.  **Run the Flask Server**:
    From the root directory, run the main application file:

    ```bash
    python backend/src/app.py
    ```

3.  **Access the Application**:
    Open your web browser and go to `http://127.0.0.1:5000`.

The application should now be running locally!
