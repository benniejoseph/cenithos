# WealthWise - Essential Setup Scripts and Configuration Files

## 1. Project Setup Script (scripts/setup.sh)

```bash
#!/bin/bash
# WealthWise Project Setup Script

set -e  # Exit on error

echo "🚀 WealthWise Project Setup"
echo "=========================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check prerequisites
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed${NC}"
        echo "Please install $1 and run this script again"
        exit 1
    else
        echo -e "${GREEN}✓ $1 is installed${NC}"
    fi
}

echo -e "\n${YELLOW}Checking prerequisites...${NC}"
check_command flutter
check_command node
check_command npm
check_command python3
check_command git
check_command firebase

# Create project structure
echo -e "\n${YELLOW}Creating project structure...${NC}"
mkdir -p wealthwise/{mobile,backend,ai,docs,scripts}
mkdir -p wealthwise/docs/{api,guides,architecture,deployment}
mkdir -p wealthwise/.github/workflows

# Setup Flutter project
echo -e "\n${YELLOW}Setting up Flutter mobile app...${NC}"
cd wealthwise/mobile
flutter create . --org com.wealthwise --project-name wealthwise --platforms ios,android

# Add Flutter dependencies
cat > pubspec.yaml << 'EOF'
name: wealthwise
description: Financial Intelligence Platform for Indian Users
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Dependency Injection
  get_it: ^7.6.0
  injectable: ^2.3.0
  
  # Networking
  dio: ^5.3.2
  retrofit: ^4.0.1
  pretty_dio_logger: ^1.3.1
  
  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0
  hive_flutter: ^1.1.0
  
  # Firebase
  firebase_core: ^2.15.0
  firebase_auth: ^4.7.2
  cloud_firestore: ^4.8.4
  firebase_storage: ^11.2.5
  firebase_analytics: ^10.4.4
  firebase_crashlytics: ^3.3.4
  
  # UI/UX
  flutter_svg: ^2.0.7
  cached_network_image: ^3.2.3
  shimmer: ^3.0.0
  lottie: ^2.6.0
  flutter_animate: ^4.2.0
  
  # Utilities
  intl: ^0.18.1
  uuid: ^3.0.7
  rxdart: ^0.27.7
  dartz: ^0.10.1
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  
  # Security
  local_auth: ^2.1.6
  encrypt: ^5.0.1
  
  # Others
  url_launcher: ^6.1.12
  permission_handler: ^10.4.3
  image_picker: ^1.0.2
  path_provider: ^2.1.0
  connectivity_plus: ^4.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.2
  build_runner: ^2.4.6
  injectable_generator: ^2.4.0
  retrofit_generator: ^7.0.8
  freezed: ^2.4.1
  json_serializable: ^6.7.1
  mockito: ^5.4.2
  bloc_test: ^9.1.4

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/animations/
    - assets/icons/
  
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
    - family: RobotoMono
      fonts:
        - asset: assets/fonts/RobotoMono-Regular.ttf
EOF

flutter pub get

# Setup Backend
echo -e "\n${YELLOW}Setting up Backend services...${NC}"
cd ../backend
npm init -y

# Create package.json
cat > package.json << 'EOF'
{
  "name": "wealthwise-backend",
  "version": "1.0.0",
  "description": "WealthWise Backend Services",
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "watch": "tsc -w",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log",
    "test": "jest",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts"
  },
  "engines": {
    "node": "18"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "express": "^4.18.2",
    "firebase-admin": "^11.10.1",
    "firebase-functions": "^4.4.1",
    "joi": "^17.9.2",
    "jsonwebtoken": "^9.0.2",
    "lodash": "^4.17.21",
    "moment": "^2.29.4",
    "node-fetch": "^2.6.12",
    "uuid": "^9.0.0"
  },
  "devDependencies": {
    "@types/cors": "^2.8.13",
    "@types/express": "^4.17.17",
    "@types/jest": "^29.5.3",
    "@types/jsonwebtoken": "^9.0.2",
    "@types/lodash": "^4.14.196",
    "@types/node": "^20.4.5",
    "@types/uuid": "^9.0.2",
    "@typescript-eslint/eslint-plugin": "^6.2.0",
    "@typescript-eslint/parser": "^6.2.0",
    "eslint": "^8.46.0",
    "eslint-config-prettier": "^8.9.0",
    "jest": "^29.6.2",
    "prettier": "^3.0.0",
    "ts-jest": "^29.1.1",
    "typescript": "^5.1.6"
  }
}
EOF

# Create tsconfig.json
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "lib": ["es2017", "es2018.asyncgenerator", "es2018.asynciterable"],
    "types": ["node", "jest"]
  },
  "compileOnSave": true,
  "include": [
    "src"
  ],
  "exclude": [
    "node_modules"
  ]
}
EOF

npm install

# Setup AI Services
echo -e "\n${YELLOW}Setting up AI services...${NC}"
cd ../ai

# Create requirements.txt
cat > requirements.txt << 'EOF'
# Core
fastapi==0.103.1
uvicorn[standard]==0.23.2
python-dotenv==1.0.0
pydantic==2.3.0
pydantic-settings==2.0.3

# AI/ML
openai==0.28.0
langchain==0.0.285
pinecone-client==2.2.4
numpy==1.25.2
pandas==2.1.0
scikit-learn==1.3.0

# Database
redis==5.0.0
motor==3.3.1

# Utilities
httpx==0.24.1
python-multipart==0.0.6
aiofiles==23.2.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4

# Development
pytest==7.4.0
pytest-asyncio==0.21.1
black==23.7.0
flake8==6.1.0
mypy==1.5.1

# Monitoring
prometheus-fastapi-instrumentator==6.1.0
sentry-sdk==1.29.2
EOF

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create .env.example
echo -e "\n${YELLOW}Creating environment configuration...${NC}"
cd ..
cat > .env.example << 'EOF'
# Environment
NODE_ENV=development
APP_ENV=development

# Firebase Configuration
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY=your_private_key
FIREBASE_CLIENT_EMAIL=your_client_email

# API Keys
OPENAI_API_KEY=your_openai_api_key
PINECONE_API_KEY=your_pinecone_api_key
PINECONE_ENVIRONMENT=us-west1-gcp

# Database URLs
REDIS_URL=redis://localhost:6379
MONGODB_URI=mongodb://localhost:27017/wealthwise

# Security
JWT_SECRET=your_jwt_secret_key
ENCRYPTION_KEY=your_encryption_key

# SMS Gateway (Optional)
SMS_API_KEY=your_sms_api_key
SMS_SENDER_ID=WLTHWS

# Email Service (Optional)
SENDGRID_API_KEY=your_sendgrid_api_key
FROM_EMAIL=noreply@wealthwise.app

# Analytics (Optional)
MIXPANEL_TOKEN=your_mixpanel_token
SENTRY_DSN=your_sentry_dsn

# Market Data APIs (Optional)
ALPHA_VANTAGE_API_KEY=your_alpha_vantage_key
TWELVE_DATA_API_KEY=your_twelve_data_key
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
venv/
__pycache__/
*.pyc
.pytest_cache/

# Environment files
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# Build outputs
dist/
build/
lib/
*.log

# Mobile specific
mobile/.dart_tool/
mobile/.flutter-plugins
mobile/.flutter-plugins-dependencies
mobile/.packages
mobile/.pub-cache/
mobile/.pub/
mobile/build/
mobile/ios/Pods/
mobile/ios/.symlinks/
mobile/ios/Flutter/Flutter.framework
mobile/ios/Flutter/Flutter.podspec
mobile/android/.gradle/
mobile/android/captures/
mobile/android/local.properties
mobile/android/app/debug/
mobile/android/app/profile/
mobile/android/app/release/

# Backend specific
backend/lib/
backend/*.log

# AI specific
ai/*.egg-info/
ai/.mypy_cache/

# Firebase
.firebase/
firebase-debug.log
firestore-debug.log
ui-debug.log

# Certificates
*.pem
*.p12
*.key
*.cer

# Coverage
coverage/
*.lcov
EOF

# Create GitHub Actions workflows
echo -e "\n${YELLOW}Setting up CI/CD workflows...${NC}"

# Mobile CI/CD
cat > .github/workflows/mobile_ci.yml << 'EOF'
name: Mobile CI/CD

on:
  push:
    branches: [main, develop]
    paths:
      - 'mobile/**'
      - '.github/workflows/mobile_ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'mobile/**'

defaults:
  run:
    working-directory: mobile

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: mobile/coverage/lcov.info
          flags: mobile

  build_android:
    name: Build Android
    needs: analyze
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '11'
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Build App Bundle
        run: flutter build appbundle --release
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: android-artifacts
          path: |
            mobile/build/app/outputs/flutter-apk/app-release.apk
            mobile/build/app/outputs/bundle/release/app-release.aab

  build_ios:
    name: Build iOS
    needs: analyze
    runs-on: macos-latest
    if: github.event_name == 'push'
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: ios-artifacts
          path: mobile/build/ios/iphoneos/Runner.app
EOF

# Backend CI/CD
cat > .github/workflows/backend_ci.yml << 'EOF'
name: Backend CI/CD

on:
  push:
    branches: [main, develop]
    paths:
      - 'backend/**'
      - '.github/workflows/backend_ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'backend/**'

defaults:
  run:
    working-directory: backend

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        node-version: [18.x]
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run linter
        run: npm run lint
      
      - name: Run tests
        run: npm test
      
      - name: Build
        run: npm run build

  deploy:
    name: Deploy to Firebase
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: '18.x'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Deploy to Firebase
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only functions
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
          PROJECT_ID: wealthwise-prod
EOF

# AI Service CI/CD
cat > .github/workflows/ai_ci.yml << 'EOF'
name: AI Service CI/CD

on:
  push:
    branches: [main, develop]
    paths:
      - 'ai/**'
      - '.github/workflows/ai_ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'ai/**'

defaults:
  run:
    working-directory: ai

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        python-version: ['3.9', '3.10']
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
      
      - name: Lint with flake8
        run: |
          flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
          flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
      
      - name: Type check with mypy
        run: mypy .
      
      - name: Test with pytest
        run: pytest

  docker:
    name: Build Docker Image
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to Container Registry
        uses: docker/login-action@v2
        with:
          registry: gcr.io
          username: _json_key
          password: ${{ secrets.GCR_JSON_KEY }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: ./ai
          push: true
          tags: |
            gcr.io/wealthwise-prod/ai-service:latest
            gcr.io/wealthwise-prod/ai-service:${{ github.sha }}
EOF

echo -e "\n${GREEN}✅ Project setup complete!${NC}"
echo -e "\nNext steps:"
echo "1. Copy .env.example to .env and fill in your API keys"
echo "2. Run 'cd mobile && flutter run' to start the mobile app"
echo "3. Run 'cd backend && npm run serve' to start backend services"
echo "4. Run 'cd ai && uvicorn main:app --reload' to start AI services"
echo -e "\n${YELLOW}Happy coding! 🚀${NC}"
```

## 2. Mobile App Configuration Files

### mobile/lib/main.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'injection.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize dependency injection
  configureDependencies();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  // Run app
  runApp(const WealthWiseApp());
}
```

### mobile/lib/app.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_themes.dart';
import 'core/routing/app_router.dart';
import 'injection.dart';

class WealthWiseApp extends StatelessWidget {
  const WealthWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Add global BLoCs here
      ],
      child: MaterialApp.router(
        title: 'WealthWise',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.darkTheme,
        routerConfig: getIt<AppRouter>().config(),
      ),
    );
  }
}
```

### mobile/lib/injection.dart
```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
void configureDependencies() => $initGetIt(getIt);
```

## 3. Backend Configuration Files

### backend/src/index.ts
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import express from 'express';
import cors from 'cors';

// Initialize Firebase Admin
admin.initializeApp();

// Create Express app
const app = express();

// Middleware
app.use(cors({ origin: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Import routes
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';
import transactionRoutes from './routes/transaction.routes';
import aiRoutes from './routes/ai.routes';

// API routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/transactions', transactionRoutes);
app.use('/api/v1/ai', aiRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: {
      message: err.message || 'Internal server error',
      status: err.status || 500,
    },
  });
});

// Export as Firebase Function
export const api = functions
  .region('asia-south1') // Mumbai region for Indian users
  .https.onRequest(app);
```

## 4. AI Service Configuration

### ai/main.py
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from core.config import settings
from core.database import init_db
from api.routes import agents, health
from core.logging import setup_logging

# Setup logging
setup_logging()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await init_db()
    yield
    # Shutdown
    # Add cleanup code here

# Create FastAPI app
app = FastAPI(
    title="WealthWise AI Service",
    description="AI-powered financial intelligence service",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router, tags=["health"])
app.include_router(agents.router, prefix="/api/v1/agents", tags=["agents"])

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info"
    )
```

### ai/Dockerfile
```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## 5. Database Schema (backend/src/models/schemas.ts)

```typescript
// User Schema
export interface User {
  uid: string;
  email: string;
  phoneNumber: string;
  profile: {
    firstName: string;
    lastName: string;
    dateOfBirth: Date;
    occupation: string;
    monthlyIncome: number;
    pan?: string; // Encrypted
    aadhaar?: string; // Encrypted
  };
  preferences: {
    currency: string;
    fiscalYearStart: number;
    notifications: {
      email: boolean;
      sms: boolean;
      push: boolean;
      frequency: 'daily' | 'weekly' | 'monthly';
    };
  };
  security: {
    biometricEnabled: boolean;
    twoFactorEnabled: boolean;
    lastLogin: Date;
    loginHistory: Array<{
      timestamp: Date;
      ip: string;
      device: string;
    }>;
  };
  subscription: {
    plan: 'free' | 'pro' | 'premium';
    startDate: Date;
    endDate?: Date;
    autoRenew: boolean;
  };
  gamification: {
    level: number;
    xp: number;
    badges: string[];
    streakDays: number;
    achievements: string[];
  };
  createdAt: Date;
  updatedAt: Date;
}

// Transaction Schema
export interface Transaction {
  id: string;
  userId: string;
  type: 'income' | 'expense' | 'transfer';
  amount: number;
  currency: string;
  category: string;
  subcategory?: string;
  description: string;
  date: Date;
  account: {
    id: string;
    name: string;
    type: 'bank' | 'credit_card' | 'cash' | 'wallet';
  };
  tags: string[];
  attachments: string[];
  location?: {
    lat: number;
    lng: number;
    address?: string;
  };
  recurring?: {
    isRecurring: boolean;
    frequency?: 'daily' | 'weekly' | 'monthly' | 'yearly';
    endDate?: Date;
  };
  aiProcessed: {
    autoDetected: boolean;
    categoryConfidence: number;
    suggestions: string[];
    patterns: string[];
  };
  createdAt: Date;
  updatedAt: Date;
}

// Financial Goal Schema
export interface FinancialGoal {
  id: string;
  userId: string;
  name: string;
  description: string;
  targetAmount: number;
  currentAmount: number;
  targetDate: Date;
  category: 'savings' | 'investment' | 'debt' | 'purchase' | 'retirement';
  priority: 'low' | 'medium' | 'high';
  status: 'active' | 'completed' | 'paused';
  milestones: Array<{
    amount: number;
    date: Date;
    achieved: boolean;
  }>;
  aiRecommendations: string[];
  createdAt: Date;
  updatedAt: Date;
}
```

## 6. Sample Environment Configuration

### Mobile (mobile/lib/env/env.dart)
```dart
abstract class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.wealthwise.app',
  );
  
  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );
  
  static const bool isProduction = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  );
}
```

This comprehensive setup provides:

1. **Automated setup script** that creates the entire project structure
2. **CI/CD workflows** for all three components (mobile, backend, AI)
3. **Docker configuration** for AI services
4. **Database schemas** for core entities
5. **Environment configuration** templates
6. **Security-first approach** with encryption placeholders
7. **Complete dependency lists** for all platforms

You can now run `./scripts/setup.sh` to automatically create the entire project structure and start building WealthWise with Cursor!