# WealthWise - Complete Project Structure

```
wealthwise/
├── .cursorrules                    # Cursor AI rules for project
├── .gitignore                      # Git ignore file
├── README.md                       # Project overview
├── ARCHITECTURE.md                 # Technical architecture
├── IMPLEMENTATION_GUIDE.md         # Step-by-step implementation
├── FEATURES.md                     # Complete feature list
├── AI_AGENTS.md                    # AI agent documentation
├── SECURITY.md                     # Security implementation guide
├── API_DOCUMENTATION.md            # API endpoints and structure
├── DEPLOYMENT.md                   # Deployment guide
├── LICENSE                         # MIT License
│
├── mobile/                         # Flutter mobile app
│   ├── .cursorrules               # Flutter-specific Cursor rules
│   ├── pubspec.yaml               # Flutter dependencies
│   ├── analysis_options.yaml      # Dart linting rules
│   ├── README.md                  # Mobile app documentation
│   │
│   ├── lib/
│   │   ├── main.dart              # App entry point
│   │   ├── app.dart               # App configuration
│   │   ├── env/                   # Environment configs
│   │   │   ├── env.dart
│   │   │   ├── dev.dart
│   │   │   └── prod.dart
│   │   │
│   │   ├── core/                  # Core functionality
│   │   │   ├── constants/
│   │   │   │   ├── app_colors.dart
│   │   │   │   ├── app_strings.dart
│   │   │   │   └── app_themes.dart
│   │   │   ├── errors/
│   │   │   │   ├── failures.dart
│   │   │   │   └── exceptions.dart
│   │   │   ├── network/
│   │   │   │   ├── api_client.dart
│   │   │   │   └── network_info.dart
│   │   │   ├── routing/
│   │   │   │   ├── app_router.dart
│   │   │   │   └── route_guards.dart
│   │   │   ├── services/
│   │   │   │   ├── analytics_service.dart
│   │   │   │   ├── crash_service.dart
│   │   │   │   ├── logger_service.dart
│   │   │   │   └── storage_service.dart
│   │   │   └── utils/
│   │   │       ├── validators.dart
│   │   │       ├── formatters.dart
│   │   │       └── extensions.dart
│   │   │
│   │   ├── data/                  # Data layer
│   │   │   ├── datasources/
│   │   │   │   ├── local/
│   │   │   │   │   ├── secure_storage.dart
│   │   │   │   │   └── cache_storage.dart
│   │   │   │   └── remote/
│   │   │   │       ├── auth_remote_datasource.dart
│   │   │   │       ├── transaction_remote_datasource.dart
│   │   │   │       └── ai_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── user_model.dart
│   │   │   │   ├── transaction_model.dart
│   │   │   │   ├── account_model.dart
│   │   │   │   └── ai_response_model.dart
│   │   │   └── repositories/
│   │   │       ├── auth_repository_impl.dart
│   │   │       ├── transaction_repository_impl.dart
│   │   │       └── ai_repository_impl.dart
│   │   │
│   │   ├── domain/                # Domain layer
│   │   │   ├── entities/
│   │   │   │   ├── user.dart
│   │   │   │   ├── transaction.dart
│   │   │   │   ├── account.dart
│   │   │   │   └── financial_goal.dart
│   │   │   ├── repositories/
│   │   │   │   ├── auth_repository.dart
│   │   │   │   ├── transaction_repository.dart
│   │   │   │   └── ai_repository.dart
│   │   │   └── usecases/
│   │   │       ├── auth/
│   │   │       ├── transactions/
│   │   │       └── ai_agents/
│   │   │
│   │   ├── presentation/          # Presentation layer
│   │   │   ├── blocs/            # State management
│   │   │   │   ├── auth/
│   │   │   │   ├── dashboard/
│   │   │   │   ├── transactions/
│   │   │   │   └── ai_chat/
│   │   │   ├── pages/            # Screen widgets
│   │   │   │   ├── splash/
│   │   │   │   ├── onboarding/
│   │   │   │   ├── auth/
│   │   │   │   ├── dashboard/
│   │   │   │   ├── transactions/
│   │   │   │   ├── ai_assistant/
│   │   │   │   ├── investments/
│   │   │   │   ├── reports/
│   │   │   │   └── settings/
│   │   │   ├── widgets/          # Reusable widgets
│   │   │   │   ├── common/
│   │   │   │   ├── charts/
│   │   │   │   ├── cards/
│   │   │   │   └── animations/
│   │   │   └── themes/           # App themes
│   │   │
│   │   └── injection.dart         # Dependency injection
│   │
│   ├── assets/                    # Static assets
│   │   ├── images/
│   │   ├── animations/
│   │   ├── fonts/
│   │   └── icons/
│   │
│   └── test/                      # Test files
│       ├── unit/
│       ├── widget/
│       └── integration/
│
├── backend/                       # Backend services
│   ├── .cursorrules              # Backend-specific Cursor rules
│   ├── package.json              # Node.js dependencies
│   ├── tsconfig.json             # TypeScript config
│   ├── README.md                 # Backend documentation
│   │
│   ├── functions/                # Cloud functions
│   │   ├── src/
│   │   │   ├── index.ts         # Entry point
│   │   │   ├── auth/
│   │   │   ├── transactions/
│   │   │   ├── ai/
│   │   │   ├── reports/
│   │   │   └── integrations/
│   │   └── tests/
│   │
│   ├── shared/                   # Shared utilities
│   │   ├── types/
│   │   ├── utils/
│   │   └── constants/
│   │
│   └── scripts/                  # Utility scripts
│       ├── deploy.sh
│       ├── backup.sh
│       └── migrate.js
│
├── ai/                          # AI agent implementations
│   ├── .cursorrules            # AI-specific Cursor rules
│   ├── requirements.txt        # Python dependencies
│   ├── README.md               # AI documentation
│   │
│   ├── agents/                 # AI agents
│   │   ├── alex_expense_coach.py
│   │   ├── emma_investment_educator.py
│   │   ├── thomas_tax_advisor.py
│   │   ├── sarah_budget_mentor.py
│   │   ├── michael_wealth_coach.py
│   │   └── rachel_risk_analyst.py
│   │
│   ├── core/                   # Core AI functionality
│   │   ├── orchestrator.py
│   │   ├── context_manager.py
│   │   ├── memory_store.py
│   │   └── prompt_templates.py
│   │
│   ├── utils/                  # AI utilities
│   │   ├── embeddings.py
│   │   ├── parsers.py
│   │   └── validators.py
│   │
│   └── tests/                  # AI tests
│
├── docs/                       # Documentation
│   ├── api/                    # API documentation
│   ├── guides/                 # User guides
│   ├── architecture/           # Architecture diagrams
│   └── deployment/             # Deployment guides
│
├── scripts/                    # Project scripts
│   ├── setup.sh               # Initial setup
│   ├── generate_icons.sh      # Icon generation
│   └── release.sh             # Release automation
│
└── .github/                   # GitHub workflows
    └── workflows/
        ├── mobile_ci.yml
        ├── backend_ci.yml
        └── ai_ci.yml
```

## File Contents

### 1. Root .cursorrules
```
# WealthWise Project Cursor Rules

## Project Overview
WealthWise is a comprehensive financial intelligence platform for Indian users that provides AI-powered financial analysis, education, and advisory services without handling actual transactions.

## Tech Stack
- Mobile: Flutter (Dart)
- Backend: Firebase/Supabase + Cloud Functions (TypeScript)
- AI: Python (FastAPI) + OpenAI GPT-4
- Database: Firestore/PostgreSQL
- Vector DB: Pinecone
- Cache: Redis

## Code Standards

### General
- Use descriptive variable names
- Add comprehensive comments for complex logic
- Follow DRY principle
- Implement proper error handling
- Write unit tests for all business logic

### Flutter/Dart
- Follow effective dart guidelines
- Use clean architecture pattern
- Implement BLoC for state management
- Use GetIt for dependency injection
- Maintain 80% code coverage

### TypeScript
- Use strict mode
- Implement proper typing
- Use async/await over promises
- Follow ESLint rules
- Use interfaces for data contracts

### Python
- Follow PEP 8
- Use type hints
- Implement proper logging
- Use environment variables for config
- Document all functions

## Security First
- Never store sensitive data in plain text
- Implement proper authentication
- Use encryption for PII
- Follow OWASP guidelines
- Regular security audits

## AI Guidelines
- Always provide context to AI agents
- Implement rate limiting
- Cache common responses
- Use streaming for long responses
- Monitor token usage

## Git Workflow
- Feature branches from develop
- Meaningful commit messages
- PR reviews required
- Automated testing before merge
- Semantic versioning

## Documentation
- Update docs with code changes
- Include examples in documentation
- Maintain API documentation
- Document architectural decisions
- Keep README files current
```

### 2. Root README.md
```markdown
# WealthWise - Financial Intelligence Platform

<p align="center">
  <img src="assets/logo.png" alt="WealthWise Logo" width="200"/>
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/Flutter-3.x-blue.svg" alt="Flutter Version"></a>
  <a href="#"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
  <a href="#"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome"></a>
</p>

## 🎯 Overview

WealthWise is a comprehensive financial intelligence platform designed specifically for Indian users. It provides AI-powered financial analysis, personalized education, and advisory services without handling actual financial transactions.

## ✨ Key Features

- 🤖 **6 Specialized AI Agents** for different financial aspects
- 📊 **Comprehensive Financial Analytics** with real-time insights
- 🎓 **Personalized Financial Education** modules
- 🔒 **Bank-grade Security** with end-to-end encryption
- 📱 **Cross-platform** support (iOS, Android, Web)
- 🎮 **Gamified Learning** experience
- 🏆 **Goal Tracking** and achievement system

## 🚀 Quick Start

### Prerequisites
- Flutter 3.x
- Node.js 18+
- Python 3.9+
- Firebase CLI
- Git

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/wealthwise.git
cd wealthwise
```

2. Run setup script
```bash
./scripts/setup.sh
```

3. Configure environment variables
```bash
cp .env.example .env
# Edit .env with your API keys
```

4. Start development
```bash
# Mobile app
cd mobile && flutter run

# Backend
cd backend && npm run dev

# AI services
cd ai && python main.py
```

## 📖 Documentation

- [Architecture Overview](ARCHITECTURE.md)
- [Implementation Guide](IMPLEMENTATION_GUIDE.md)
- [API Documentation](API_DOCUMENTATION.md)
- [Security Guide](SECURITY.md)
- [Deployment Guide](DEPLOYMENT.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- OpenAI for GPT-4 API
- Our beta testers for valuable feedback

---

<p align="center">Made with ❤️ in India</p>
```

### 3. IMPLEMENTATION_GUIDE.md
```markdown
# WealthWise Implementation Guide

## 📋 Table of Contents

1. [Phase 1: Project Setup](#phase-1-project-setup)
2. [Phase 2: Core Infrastructure](#phase-2-core-infrastructure)
3. [Phase 3: Authentication & Security](#phase-3-authentication--security)
4. [Phase 4: Data Management](#phase-4-data-management)
5. [Phase 5: AI Integration](#phase-5-ai-integration)
6. [Phase 6: Feature Implementation](#phase-6-feature-implementation)
7. [Phase 7: Testing & QA](#phase-7-testing--qa)
8. [Phase 8: Deployment](#phase-8-deployment)

## Phase 1: Project Setup (Week 1)

### 1.1 Development Environment
```bash
# Install Flutter
curl -fsSL https://flutter.dev/setup.sh | bash

# Install Node.js (using nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18

# Install Python (using pyenv)
curl https://pyenv.run | bash
pyenv install 3.9.0
pyenv global 3.9.0

# Install Firebase CLI
npm install -g firebase-tools

# Install project dependencies
./scripts/setup.sh
```

### 1.2 Project Structure Setup
```bash
# Create project structure
mkdir -p wealthwise/{mobile,backend,ai,docs,scripts}

# Initialize Flutter project
cd mobile
flutter create . --org com.wealthwise --project-name wealthwise

# Initialize backend
cd ../backend
npm init -y
npm install typescript @types/node ts-node nodemon

# Initialize AI services
cd ../ai
python -m venv venv
source venv/bin/activate
pip install fastapi uvicorn openai pinecone-client
```

### 1.3 Version Control
```bash
# Initialize git
git init
git add .
git commit -m "Initial project setup"

# Create branches
git branch develop
git branch staging
git checkout develop
```

## Phase 2: Core Infrastructure (Week 2-3)

### 2.1 Backend Setup

#### Firebase Configuration
```typescript
// backend/functions/src/config/firebase.ts
import * as admin from 'firebase-admin';

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: 'https://wealthwise-prod.firebaseio.com'
});

export const db = admin.firestore();
export const auth = admin.auth();
export const storage = admin.storage();
```

#### API Structure
```typescript
// backend/functions/src/index.ts
import * as functions from 'firebase-functions';
import express from 'express';
import cors from 'cors';

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Import routes
import authRoutes from './routes/auth';
import transactionRoutes from './routes/transactions';
import aiRoutes from './routes/ai';

// Apply routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/transactions', transactionRoutes);
app.use('/api/v1/ai', aiRoutes);

export const api = functions.https.onRequest(app);
```

### 2.2 Mobile App Architecture

#### Clean Architecture Setup
```dart
// mobile/lib/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => $initGetIt(getIt);

// Setup in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(WealthWiseApp());
}
```

#### State Management with BLoC
```dart
// mobile/lib/presentation/blocs/auth/auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;
  
  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signOut,
  }) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
  }
}
```

### 2.3 AI Service Architecture

```python
# ai/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from agents import router as agents_router
from core.config import settings

app = FastAPI(title="WealthWise AI Service")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(agents_router, prefix="/api/v1/agents")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

## Phase 3: Authentication & Security (Week 4)

### 3.1 Implement Multi-factor Authentication

```dart
// mobile/lib/data/datasources/auth_remote_datasource.dart
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final FirebaseAuth firebaseAuth;
  
  @override
  Future<UserModel> signIn(String email, String password) async {
    try {
      // Firebase authentication
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get custom token from backend
      final response = await apiClient.post('/auth/login', {
        'uid': credential.user!.uid,
      });
      
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<void> enableBiometric() async {
    final localAuth = LocalAuthentication();
    final isAvailable = await localAuth.canCheckBiometrics;
    
    if (isAvailable) {
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Enable biometric for quick access',
        options: AuthenticationOptions(biometricOnly: true),
      );
      
      if (didAuthenticate) {
        await secureStorage.write(key: 'biometric_enabled', value: 'true');
      }
    }
  }
}
```

### 3.2 Implement End-to-End Encryption

```dart
// mobile/lib/core/security/encryption.dart
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  late final Key _key;
  late final IV _iv;
  late final Encrypter _encrypter;
  
  EncryptionService() {
    _key = Key.fromSecureRandom(32);
    _iv = IV.fromSecureRandom(16);
    _encrypter = Encrypter(AES(_key));
  }
  
  String encrypt(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }
  
  String decrypt(String encryptedText) {
    final encrypted = Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }
}
```

## Phase 4: Data Management (Week 5-6)

### 4.1 Transaction Data Model

```dart
// mobile/lib/domain/entities/transaction.dart
class Transaction extends Equatable {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String currency;
  final String category;
  final String? subcategory;
  final String description;
  final DateTime date;
  final Account account;
  final List<String> tags;
  final List<String> attachments;
  final Location? location;
  final AIProcessedData? aiData;
  
  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.category,
    this.subcategory,
    required this.description,
    required this.date,
    required this.account,
    required this.tags,
    required this.attachments,
    this.location,
    this.aiData,
  });
}
```

### 4.2 SMS Parser Implementation

```dart
// mobile/lib/core/services/sms_parser_service.dart
class SmsParserService {
  final List<BankSmsPattern> patterns = [
    BankSmsPattern(
      bank: 'HDFC',
      regex: r'Rs\.?(\d+(?:\.\d{2})?).*(?:debited|credited).*AC.*(\d{4})',
      amountGroup: 1,
      typePattern: r'(debited|credited)',
    ),
    // Add more bank patterns
  ];
  
  Future<Transaction?> parseSms(String smsBody) async {
    for (final pattern in patterns) {
      final match = pattern.regex.firstMatch(smsBody);
      if (match != null) {
        final amount = double.parse(match.group(pattern.amountGroup)!);
        final type = _extractTransactionType(smsBody, pattern.typePattern);
        
        // Use AI to categorize
        final category = await _aiCategorize(smsBody);
        
        return Transaction(
          // Build transaction object
        );
      }
    }
    return null;
  }
}
```

## Phase 5: AI Integration (Week 7-8)

### 5.1 AI Agent Implementation

```python
# ai/agents/alex_expense_coach.py
from typing import Dict, List
import openai
from .base_agent import BaseAgent

class AlexExpenseCoach(BaseAgent):
    def __init__(self):
        super().__init__(
            name="Alex",
            role="Expense Coach",
            personality={
                "tone": "analytical_yet_friendly",
                "approach": "detail_oriented",
                "communication": "data_driven_insights"
            }
        )
    
    async def analyze_spending_patterns(self, transactions: List[Dict]) -> Dict:
        # Analyze transactions
        patterns = self._identify_patterns(transactions)
        anomalies = self._detect_anomalies(transactions)
        
        # Generate insights using GPT-4
        prompt = self._build_analysis_prompt(patterns, anomalies)
        
        response = await openai.ChatCompletion.acreate(
            model="gpt-4",
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            stream=True
        )
        
        return {
            "patterns": patterns,
            "anomalies": anomalies,
            "insights": response,
            "recommendations": self._generate_recommendations(patterns)
        }
```

### 5.2 Context Management

```python
# ai/core/context_manager.py
import pinecone
from typing import Dict, List
import numpy as np

class ContextManager:
    def __init__(self):
        pinecone.init(
            api_key=os.getenv("PINECONE_API_KEY"),
            environment="us-west1-gcp"
        )
        self.index = pinecone.Index("wealthwise-context")
    
    async def store_conversation(self, user_id: str, conversation: Dict):
        # Generate embedding
        embedding = await self._generate_embedding(conversation['content'])
        
        # Store in Pinecone
        self.index.upsert(
            vectors=[{
                "id": f"{user_id}_{conversation['timestamp']}",
                "values": embedding,
                "metadata": {
                    "user_id": user_id,
                    "agent": conversation['agent'],
                    "content": conversation['content'],
                    "timestamp": conversation['timestamp']
                }
            }]
        )
    
    async def retrieve_context(self, user_id: str, query: str, top_k: int = 5):
        # Generate query embedding
        query_embedding = await self._generate_embedding(query)
        
        # Search similar contexts
        results = self.index.query(
            vector=query_embedding,
            filter={"user_id": user_id},
            top_k=top_k,
            include_metadata=True
        )
        
        return results['matches']
```

## Phase 6: Feature Implementation (Week 9-16)

### 6.1 Dashboard Implementation

```dart
// mobile/lib/presentation/pages/dashboard/dashboard_page.dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoaded) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                flexibleSpace: FlexibleSpaceBar(
                  background: NetWorthCard(
                    netWorth: state.financialSummary.netWorth,
                    monthlyChange: state.financialSummary.monthlyChange,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: QuickActionsGrid(),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  AIInsightsCarousel(insights: state.aiInsights),
                  AccountsSection(accounts: state.accounts),
                  RecentTransactionsSection(
                    transactions: state.recentTransactions
                  ),
                ]),
              ),
            ],
          );
        }
        return LoadingIndicator();
      },
    );
  }
}
```

### 6.2 AI Chat Interface

```dart
// mobile/lib/presentation/pages/ai_assistant/ai_chat_page.dart
class AIChatPage extends StatefulWidget {
  @override
  _AIChatPageState createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final List<AIAgent> agents = [
    AlexAgent(),
    EmmaAgent(),
    ThomasAgent(),
    SarahAgent(),
    MichaelAgent(),
    RachelAgent(),
  ];
  
  AIAgent? selectedAgent;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedAgent?.name ?? 'AI Assistant'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: AgentSelector(
            agents: agents,
            onAgentSelected: (agent) {
              setState(() => selectedAgent = agent);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: MessagesList(
              agent: selectedAgent,
            ),
          ),
          ChatInputBar(
            onSend: (message) {
              context.read<AIChatBloc>().add(
                SendMessage(
                  agent: selectedAgent!,
                  message: message,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### 6.3 Gamification System

```dart
// mobile/lib/domain/entities/gamification.dart
class UserLevel {
  final int level;
  final String title;
  final int currentXP;
  final int requiredXP;
  final List<Badge> unlockedBadges;
  
  double get progress => currentXP / requiredXP;
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final int rewardXP;
  final Duration duration;
  final ChallengeType type;
  final Map<String, dynamic> requirements;
}

// mobile/lib/presentation/widgets/gamification/level_progress_card.dart
class LevelProgressCard extends StatelessWidget {
  final UserLevel userLevel;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Level ${userLevel.level}'),
                Text(userLevel.title),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: userLevel.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(Colors.purple),
            ),
            SizedBox(height: 4),
            Text('${userLevel.currentXP}/${userLevel.requiredXP} XP'),
          ],
        ),
      ),
    );
  }
}
```

## Phase 7: Testing & QA (Week 17-18)

### 7.1 Unit Testing

```dart
// mobile/test/unit/domain/usecases/analyze_expenses_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockAIRepository extends Mock implements AIRepository {}

void main() {
  late AnalyzeExpenses useCase;
  late MockTransactionRepository mockTransactionRepository;
  late MockAIRepository mockAIRepository;
  
  setUp(() {
    mockTransactionRepository = MockTransactionRepository();
    mockAIRepository = MockAIRepository();
    useCase = AnalyzeExpenses(
      transactionRepository: mockTransactionRepository,
      aiRepository: mockAIRepository,
    );
  });
  
  test('should return expense analysis when successful', () async {
    // Arrange
    final transactions = [/* test data */];
    final expectedAnalysis = ExpenseAnalysis(/* test data */);
    
    when(mockTransactionRepository.getTransactions(any))
        .thenAnswer((_) async => Right(transactions));
    when(mockAIRepository.analyzeExpenses(transactions))
        .thenAnswer((_) async => Right(expectedAnalysis));
    
    // Act
    final result = await useCase(AnalyzeExpensesParams(userId: 'test'));
    
    // Assert
    expect(result, Right(expectedAnalysis));
  });
}
```

### 7.2 Widget Testing

```dart
// mobile/test/widget/presentation/widgets/transaction_card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('TransactionCard displays correct information', (tester) async {
    final transaction = Transaction(
      id: '1',
      description: 'Coffee',
      amount: 150,
      category: 'Food & Dining',
      date: DateTime.now(),
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionCard(transaction: transaction),
        ),
      ),
    );
    
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('₹150'), findsOneWidget);
    expect(find.text('Food & Dining'), findsOneWidget);
  });
}
```

### 7.3 Integration Testing

```dart
// mobile/test/integration/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Authentication Flow', () {
    testWidgets('User can sign up, sign in, and sign out', (tester) async {
      await tester.pumpWidget(WealthWiseApp());
      
      // Navigate to sign up
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      
      // Fill sign up form
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'Test@123');
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      
      // Verify dashboard is shown
      expect(find.text('Dashboard'), findsOneWidget);
      
      // Sign out
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();
      
      // Verify back at login
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
```

## Phase 8: Deployment (Week 19-20)

### 8.1 CI/CD Pipeline

```yaml
# .github/workflows/mobile_ci.yml
name: Mobile CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Install dependencies
        run: cd mobile && flutter pub get
      
      - name: Run tests
        run: cd mobile && flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: mobile/coverage/lcov.info
  
  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build APK
        run: |
          cd mobile
          flutter build apk --release
      
      - name: Build App Bundle
        run: |
          cd mobile
          flutter build appbundle --release
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: release-artifacts
          path: |
            mobile/build/app/outputs/flutter-apk/app-release.apk
            mobile/build/app/outputs/bundle/release/app-release.aab
```

### 8.2 Production Deployment

```bash
# scripts/deploy.sh
#!/bin/bash
set -e

echo "🚀 Starting WealthWise deployment..."

# Deploy backend
echo "📦 Deploying backend functions..."
cd backend
npm run build
firebase deploy --only functions

# Deploy AI services
echo "🤖 Deploying AI services..."
cd ../ai
docker build -t wealthwise-ai:latest .
docker tag wealthwise-ai:latest gcr.io/wealthwise-prod/ai:latest
docker push gcr.io/wealthwise-prod/ai:latest
kubectl apply -f k8s/

# Deploy mobile apps
echo "📱 Building mobile apps..."
cd ../mobile
flutter build appbundle --release
flutter build ipa --release

echo "✅ Deployment complete!"
```

## 📝 Additional Documentation Files

### 4. AI_AGENTS.md
```markdown
# WealthWise AI Agents Documentation

## Overview

WealthWise features 6 specialized AI agents, each with unique personalities and expertise areas. All agents are powered by OpenAI GPT-4 and maintain context through vector embeddings.

## Agent Profiles

### 1. Alex - Personal Expense Coach
- **Specialty**: Expense analysis and spending optimization
- **Personality**: Analytical yet friendly, detail-oriented
- **Key Features**:
  - Spending pattern recognition
  - Budget leak detection
  - Subscription management
  - Anomaly alerts

### 2. Emma - Investment Educator
- **Specialty**: Investment education and portfolio analysis
- **Personality**: Knowledgeable educator, patient explainer
- **Key Features**:
  - Portfolio health analysis
  - Market insights
  - Investment education
  - Risk assessment

### 3. Thomas - Tax Strategy Advisor
- **Specialty**: Tax optimization and compliance
- **Personality**: Professional, compliance-focused
- **Key Features**:
  - Tax saving recommendations
  - Deduction optimization
  - Compliance calendar
  - Filing assistance

### 4. Sarah - Budget Mentor
- **Specialty**: Budgeting and financial planning
- **Personality**: Encouraging, supportive, practical
- **Key Features**:
  - Budget creation
  - Goal setting
  - Savings optimization
  - Debt management

### 5. Michael - Wealth Building Coach
- **Specialty**: Long-term wealth strategies
- **Personality**: Visionary, strategic thinker
- **Key Features**:
  - Wealth accumulation strategies
  - Retirement planning
  - Passive income ideas
  - Financial independence roadmap

### 6. Rachel - Risk Analyst
- **Specialty**: Risk assessment and financial health
- **Personality**: Cautious, protective, thorough
- **Key Features**:
  - Financial health scoring
  - Risk exposure analysis
  - Insurance gap analysis
  - Emergency preparedness

## Implementation Details

### Agent Selection Algorithm
```python
def select_agent(user_query: str, context: Dict) -> Agent:
    # Analyze query intent
    intent = analyze_intent(user_query)
    
    # Score each agent's relevance
    scores = {}
    for agent in all_agents:
        scores[agent.name] = calculate_relevance_score(
            query=user_query,
            agent_expertise=agent.expertise,
            user_context=context
        )
    
    # Return highest scoring agent
    return max(scores, key=scores.get)
```

### Context Management
Each agent maintains:
- Conversation history (last 10 interactions)
- User financial profile
- Previous recommendations
- User preferences and feedback

### Response Generation
1. Context retrieval from vector DB
2. Prompt construction with personality
3. GPT-4 streaming response
4. Post-processing and formatting
5. Context storage for future use
```

### 5. SECURITY.md
```markdown
# WealthWise Security Implementation Guide

## 🔒 Security Architecture

### 1. Data Encryption

#### At Rest
- **Database**: AES-256-GCM encryption for sensitive fields
- **Local Storage**: flutter_secure_storage with hardware encryption
- **Backups**: Encrypted with rotating keys

#### In Transit
- **TLS 1.3** minimum for all API calls
- **Certificate Pinning** for mobile apps
- **Request Signing** with HMAC-SHA256

### 2. Authentication & Authorization

#### Multi-Factor Authentication
```dart
class AuthService {
  Future<void> enableMFA() async {
    // 1. Generate TOTP secret
    final secret = generateTOTPSecret();
    
    // 2. Store encrypted secret
    await secureStorage.write(
      key: 'totp_secret',
      value: encrypt(secret)
    );
    
    // 3. Generate QR code
    final qrCode = generateQRCode(secret);
    
    // 4. Verify setup
    final isVerified = await verifyTOTP(userInput);
  }
}
```

#### Biometric Authentication
- Fingerprint/Face ID for app access
- Fallback to PIN/Pattern
- Secure enclave storage for biometric data

### 3. API Security

#### Rate Limiting
```typescript
const rateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', rateLimiter);
```

#### Input Validation
```typescript
const transactionSchema = Joi.object({
  amount: Joi.number().positive().required(),
  category: Joi.string().valid(...VALID_CATEGORIES).required(),
  description: Joi.string().max(500).required(),
  date: Joi.date().max('now').required(),
});

const validateTransaction = (req, res, next) => {
  const { error } = transactionSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  next();
};
```

### 4. Privacy Protection

#### Data Minimization
- Collect only essential information
- Automatic data purging after retention period
- User-controlled data deletion

#### Anonymization
```python
def anonymize_for_analytics(user_data):
    return {
        'user_id': hash_user_id(user_data['id']),
        'age_group': get_age_group(user_data['age']),
        'location': user_data['city'],  # Not precise location
        'financial_metrics': aggregate_metrics(user_data)
    }
```

### 5. Security Monitoring

#### Audit Logging
```typescript
const auditLog = (action: string, userId: string, details: any) => {
  const log = {
    timestamp: new Date(),
    action,
    userId,
    ip: req.ip,
    userAgent: req.headers['user-agent'],
    details,
  };
  
  // Store in append-only log
  await auditDB.insert(log);
};
```

#### Anomaly Detection
- Unusual login patterns
- Suspicious transaction patterns
- API abuse detection
- Real-time alerts

### 6. Incident Response Plan

1. **Detection**: Automated monitoring and alerts
2. **Containment**: Automatic account lockdown
3. **Investigation**: Detailed audit logs
4. **Recovery**: Data restoration procedures
5. **Communication**: User notification system

### 7. Compliance

#### GDPR Compliance
- Right to access data
- Right to deletion
- Data portability
- Privacy by design

#### Indian Data Protection
- Local data storage
- Cross-border transfer restrictions
- Consent management
- Grievance redressal

### 8. Security Checklist

- [ ] Enable HTTPS everywhere
- [ ] Implement certificate pinning
- [ ] Enable biometric authentication
- [ ] Set up rate limiting
- [ ] Configure WAF rules
- [ ] Enable audit logging
- [ ] Set up intrusion detection
- [ ] Regular security audits
- [ ] Penetration testing
- [ ] Security training for team
```

### 6. Mobile .cursorrules
```
# WealthWise Mobile App - Cursor Rules

## Flutter Specific Guidelines

### Architecture
- Follow Clean Architecture strictly
- Use BLoC pattern for state management
- Implement repository pattern
- Use dependency injection with GetIt

### Code Organization
```
lib/
├── core/           # App-wide utilities
├── data/           # Data layer (API, models)
├── domain/         # Business logic
├── presentation/   # UI layer
└── injection.dart  # DI setup
```

### Naming Conventions
- Files: snake_case.dart
- Classes: PascalCase
- Functions/Variables: camelCase
- Constants: SCREAMING_SNAKE_CASE
- Private: _leadingUnderscore

### State Management Rules
- One BLoC per feature
- Separate events and states
- Use Equatable for comparisons
- Stream controllers must be disposed

### UI/UX Guidelines
- Material Design 3 compliance
- Dark mode first design
- Smooth animations (60fps)
- Responsive layouts
- Accessibility support

### Performance
- Lazy load heavy widgets
- Use const constructors
- Implement pagination
- Cache network images
- Minimize rebuilds

### Testing Requirements
- Widget tests for all screens
- Unit tests for business logic
- Integration tests for critical flows
- Minimum 80% coverage

### Security
- No hardcoded secrets
- Use flutter_secure_storage
- Implement certificate pinning
- Obfuscate release builds

### Best Practices
- Handle all error states
- Show loading indicators
- Implement pull-to-refresh
- Add empty state designs
- Support offline mode

## Common Patterns

### API Call Pattern
```dart
Future<Either<Failure, Success>> makeApiCall() async {
  try {
    final response = await api.call();
    return Right(Success(response));
  } on ServerException {
    return Left(ServerFailure());
  } on NetworkException {
    return Left(NetworkFailure());
  }
}
```

### BLoC Event Handling
```dart
on<EventName>((event, emit) async {
  emit(Loading());
  final result = await useCase(event.params);
  result.fold(
    (failure) => emit(Error(failure.message)),
    (success) => emit(Loaded(success)),
  );
});
```
```

### 7. Backend .cursorrules
```
# WealthWise Backend - Cursor Rules

## TypeScript/Node.js Guidelines

### Project Structure
```
functions/
├── src/
│   ├── config/       # Configuration
│   ├── controllers/  # Route handlers
│   ├── middleware/   # Express middleware
│   ├── models/       # Data models
│   ├── routes/       # API routes
│   ├── services/     # Business logic
│   ├── utils/        # Utilities
│   └── index.ts      # Entry point
└── tests/            # Test files
```

### TypeScript Rules
- Strict mode always on
- No any types allowed
- Use interfaces over types
- Explicit return types
- Proper error types

### API Design
- RESTful endpoints
- Versioned APIs (/v1/)
- Consistent error format
- Request validation
- Response compression

### Security Requirements
- Input sanitization
- SQL injection prevention
- Rate limiting per endpoint
- JWT token validation
- CORS configuration

### Database Rules
- Use transactions
- Prepared statements
- Index optimization
- Connection pooling
- Query optimization

### Cloud Functions
- Cold start optimization
- Memory allocation tuning
- Timeout configuration
- Error handling
- Retry logic

### Testing
- Unit tests required
- Integration tests for APIs
- Load testing for scale
- Security testing
- Mock external services

### Logging & Monitoring
- Structured logging
- Error tracking
- Performance metrics
- Custom dashboards
- Alert configuration

## Code Patterns

### Error Handling
```typescript
export class AppError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public isOperational = true
  ) {
    super(message);
  }
}

// Usage
throw new AppError(404, 'Resource not found');
```

### Async Handler
```typescript
const asyncHandler = (fn: Function) => {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
```

### Service Pattern
```typescript
export class UserService {
  constructor(
    private userRepo: UserRepository,
    private cacheService: CacheService
  ) {}
  
  async getUser(id: string): Promise<User> {
    const cached = await this.cacheService.get(`user:${id}`);
    if (cached) return cached;
    
    const user = await this.userRepo.findById(id);
    await this.cacheService.set(`user:${id}`, user);
    
    return user;
  }
}
```
```

### 8. AI .cursorrules
```
# WealthWise AI Services - Cursor Rules

## Python Guidelines

### Project Structure
```
ai/
├── agents/          # AI agent implementations
├── core/            # Core functionality
├── models/          # Data models
├── prompts/         # Prompt templates
├── services/        # External services
├── utils/           # Utilities
├── tests/           # Test files
└── main.py          # FastAPI app
```

### Python Standards
- Python 3.9+ features
- Type hints mandatory
- PEP 8 compliance
- Docstrings for all functions
- No global variables

### AI Agent Rules
- Each agent separate class
- Inherit from BaseAgent
- Implement required methods
- Personality consistency
- Context awareness

### OpenAI Integration
- Stream responses
- Handle rate limits
- Token counting
- Error handling
- Cost optimization

### Prompt Engineering
- Clear system prompts
- User context injection
- Response formatting
- Safety guidelines
- Token efficiency

### Vector Database
- Efficient embeddings
- Metadata structure
- Query optimization
- Index management
- Batch operations

### FastAPI Guidelines
- Async endpoints
- Request validation
- Response models
- Error handling
- API documentation

### Testing Requirements
- Unit tests for logic
- Integration tests
- Prompt testing
- Performance tests
- Cost analysis

## AI Patterns

### Agent Base Class
```python
from abc import ABC, abstractmethod

class BaseAgent(ABC):
    def __init__(self, name: str, role: str, personality: dict):
        self.name = name
        self.role = role
        self.personality = personality
        self.system_prompt = self._build_system_prompt()
    
    @abstractmethod
    async def process(self, query: str, context: dict) -> dict:
        pass
    
    def _build_system_prompt(self) -> str:
        return f"""You are {self.name}, a {self.role}...
        Personality: {self.personality}"""
```

### Context Retrieval
```python
async def get_relevant_context(
    user_id: str,
    query: str,
    limit: int = 5
) -> List[dict]:
    # Generate embedding
    embedding = await generate_embedding(query)
    
    # Query vector DB
    results = vector_db.query(
        embedding=embedding,
        filter={"user_id": user_id},
        limit=limit
    )
    
    return results
```

### Streaming Response
```python
async def stream_ai_response(
    prompt: str,
    context: dict
) -> AsyncGenerator[str, None]:
    messages = build_messages(prompt, context)
    
    async for chunk in openai.ChatCompletion.acreate(
        model="gpt-4",
        messages=messages,
        stream=True
    ):
        if chunk.choices[0].delta.content:
            yield chunk.choices[0].delta.content
```
```

This completes the comprehensive project structure for WealthWise. The setup includes:

1. **Complete folder structure** with all necessary directories
2. **Detailed implementation guide** covering all development phases
3. **Cursor-specific rules** for each part of the stack (Mobile, Backend, AI)
4. **Security documentation** with implementation details
5. **AI agent documentation** with personality profiles and implementation
6. **Code patterns and examples** for common scenarios
7. **Testing strategies** for all components
8. **Deployment scripts** and CI/CD configuration

You can now use this structure with Cursor to build WealthWise. The `.cursorrules` files will help Cursor understand the project context and provide better code suggestions. Start by running the setup script and following the implementation guide phase by phase.

Would you like me to create any additional specific documentation or implementation files?