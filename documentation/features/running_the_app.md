# Running the Centhios Application

This document provides instructions for running the complete Centhios application, which includes the Flutter mobile app, the Firebase backend functions, and the Python AI service.

## Prerequisites

1.  **Flutter:** Ensure you have the Flutter SDK installed and configured.
2.  **Node.js:** Required for running the Firebase backend functions.
3.  **Python:** Required for the AI service.
4.  **Firebase Project:** You must have a Firebase project set up, with Firestore and Authentication enabled.
5.  **Service Account Key:** You need a Firebase service account key (`serviceAccountKey.json`) for the AI service to communicate with Firestore.
6.  **OpenAI API Key:** You need an API key from OpenAI for the AI services.
7.  **LangSmith API Key (Optional but Recommended):** For debugging and tracing the AI agents.

## Step 1: Run the Firebase Backend

The backend functions provide the API for the mobile app and the AI service.

1.  **Navigate to the functions directory:**
    ```bash
    cd backend/functions
    ```

2.  **Install dependencies:**
    ```bash
    npm install
    ```

3.  **Run the Firebase emulators:**
    ```bash
    firebase emulators:start
    ```
    This will start a local instance of the Firebase services, including Functions, Firestore, and Auth. The API will be available at `http://127.0.0.1:5001/...`.

## Step 2: Run the AI Service

The Python AI service powers the intelligent features of the application.

1.  **Navigate to the AI directory:**
    ```bash
    cd ai
    ```

2.  **Create a virtual environment (recommended):**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Set up environment variables:**
    Create a `.env` file in the `ai` directory and add the following:
    ```
    OPENAI_API_KEY="YOUR_OPENAI_API_KEY"
    GOOGLE_APPLICATION_CREDENTIALS="../backend/serviceAccountKey.json" # Adjust path if needed

    # Optional: For LangSmith Tracing
    LANGCHAIN_TRACING_V2="true"
    LANGCHAIN_ENDPOINT="https://api.smith.langchain.com"
    LANGCHAIN_API_KEY="YOUR_LANGSMITH_API_KEY"
    LANGCHAIN_PROJECT="Centhios-Financial-Agent"
    ```

5.  **Run the FastAPI server:**
    ```bash
    uvicorn main:app --reload
    ```
    The AI service will be running at `http://127.0.0.1:8000`.

## Step 3: Run the Mobile App

The Flutter mobile app is the user-facing part of the application.

1.  **Navigate to the mobile app directory:**
    ```bash
    cd mobile/centhios
    ```

2.  **Get Flutter dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    Connect a device or start an emulator, and then run:
    ```bash
    flutter run
    ```

You should now have the complete Centhios application running locally. 