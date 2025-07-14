# WealthWise - Architecture Documentation

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Client Layer                               │
├─────────────────────────┬─────────────────────┬────────────────────┤
│     Mobile App (iOS)    │  Mobile App (Android)│   Web App (PWA)    │
│       Flutter           │       Flutter        │     Flutter Web    │
└───────────┬─────────────┴─────────────────────┴────────────────────┘
            │                    HTTPS/WSS
┌───────────▼─────────────────────────────────────────────────────────┐
│                          API Gateway                                 │
│                    (Firebase Functions / Cloudflare)                 │
│  • Rate Limiting  • Authentication  • Request Routing  • CORS       │
└───────────┬─────────────────────────────────────────────────────────┘
            │
┌───────────▼─────────────────────────────────────────────────────────┐
│                       Application Services                           │
├─────────────────┬──────────────────┬──────────────┬────────────────┤
│  Auth Service   │ Transaction Svc  │   AI Service  │ Report Service │
│  (TypeScript)   │  (TypeScript)    │   (Python)    │ (TypeScript)   │
└─────────────────┴──────────────────┴──────────────┴────────────────┘
            │                    │                    │
┌───────────▼────────────────────▼────────────────────▼───────────────┐
│                         Data Layer                                   │
├──────────────┬──────────────┬──────────────┬───────────────────────┤
│  Firestore   │    Redis     │  Pinecone    │   Cloud Storage      │
│  (Primary)   │   (Cache)    │ (Vector DB)  │  (Files/Receipts)    │
└──────────────┴──────────────┴──────────────┴───────────────────────┘
```

## Mobile App Architecture (Flutter)

### Clean Architecture Pattern

```
lib/
├── presentation/          # UI Layer
│   ├── pages/            # Screen widgets
│   ├── widgets/          # Reusable widgets
│   ├── blocs/            # Business logic (BLoC)
│   └── themes/           # App themes
│
├── domain/               # Business Layer
│   ├── entities/         # Business objects
│   ├── repositories/     # Repository interfaces
│   └── usecases/         # Business logic
│
├── data/                 # Data Layer
│   ├── models/           # Data models
│   ├── datasources/      # Remote/Local data
│   └── repositories/     # Repository implementations
│
└── core/                 # Shared Code
    ├── constants/        # App constants
    ├── errors/           # Error handling
    ├── network/          # Network config
    └── utils/            # Utilities
```

### State Management Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│     UI      │────▶│    BLoC     │────▶│   UseCase   │
│   (Widget)  │◀────│   (State)   │◀────│ (Business)  │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │ Repository  │
                                        │ (Interface) │
                                        └─────────────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │    Data     │
                                        │   Source    │
                                        └─────────────┘
```

### Key Design Patterns

1. **Repository Pattern**: Abstracts data sources
2. **BLoC Pattern**: Separates business logic from UI
3. **Dependency Injection**: Using GetIt
4. **Factory Pattern**: For model creation
5. **Observer Pattern**: For reactive updates

## Backend Architecture (Node.js/TypeScript)

### Microservices Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   API Gateway                           │
└────────────────────────┬───────────────────────────────┘
                         │
    ┌────────────┬───────┴────────┬─────────────┐
    ▼            ▼                ▼             ▼
┌─────────┐ ┌──────────┐ ┌──────────────┐ ┌──────────┐
│  Auth   │ │Transaction│ │      AI      │ │ Reports  │
│ Service │ │  Service  │ │Integration   │ │ Service  │
└────┬────┘ └─────┬────┘ └──────┬───────┘ └────┬─────┘
     │            │              │              │
     └────────────┴──────────────┴──────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │   Database   │
                  └──────────────┘
```

### Service Communication

```typescript
// Event-driven architecture using Cloud Pub/Sub
export class EventBus {
  async publish(event: string, data: any): Promise<void> {
    await pubsub.topic(event).publish({
      data: Buffer.from(JSON.stringify(data)),
      attributes: {
        timestamp: new Date().toISOString(),
        version: '1.0'
      }
    });
  }

  async subscribe(event: string, handler: Function): Promise<void> {
    const subscription = pubsub.subscription(`${event}-sub`);
    subscription.on('message', async (message) => {
      const data = JSON.parse(message.data.toString());
      await handler(data);
      message.ack();
    });
  }
}
```

### Database Schema Design

```typescript
// User Collection
{
  "_id": "user_123",
  "email": "user@example.com",
  "profile": {
    "firstName": "John",
    "lastName": "Doe",
    "encrypted": {
      "pan": "encrypted_pan",
      "aadhaar": "encrypted_aadhaar"
    }
  },
  "settings": {
    "privacy": {},
    "notifications": {}
  },
  "metadata": {
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-15T00:00:00Z",
    "lastLogin": "2024-01-15T10:00:00Z"
  }
}

// Transaction Collection (Sharded by userId)
{
  "_id": "txn_123",
  "userId": "user_123",
  "amount": 1500,
  "type": "expense",
  "category": "food",
  "date": "2024-01-15T12:00:00Z",
  "metadata": {
    "source": "sms_parser",
    "confidence": 0.95
  },
  "vectors": {
    "embedding": [0.1, 0.2, ...] // For AI processing
  }
}
```

## AI Service Architecture (Python/FastAPI)

### Agent System Design

```python
# Base Agent Interface
class BaseAgent(ABC):
    def __init__(self, name: str, specialization: str):
        self.name = name
        self.specialization = specialization
        self.llm = OpenAI(model="gpt-4")
        self.memory = ConversationMemory()
        self.tools = self._initialize_tools()
    
    @abstractmethod
    async def process_query(self, query: str, context: dict) -> AgentResponse:
        pass
    
    @abstractmethod
    def _build_system_prompt(self) -> str:
        pass

# Agent Orchestrator
class AgentOrchestrator:
    def __init__(self):
        self.agents = {
            'alex': AlexExpenseCoach(),
            'emma': EmmaInvestmentEducator(),
            'thomas': ThomasTaxAdvisor(),
            'sarah': SarahBudgetMentor(),
            'michael': MichaelWealthCoach(),
            'rachel': RachelRiskAnalyst()
        }
        self.router = IntentRouter()
    
    async def route_query(self, query: str, user_context: dict) -> AgentResponse:
        intent = await self.router.classify_intent(query)
        selected_agents = self.router.get_agents_for_intent(intent)
        
        responses = []
        for agent_name in selected_agents:
            agent = self.agents[agent_name]
            response = await agent.process_query(query, user_context)
            responses.append(response)
        
        return self._merge_responses(responses)
```

### Context Management System

```python
# Vector Database Integration
class ContextManager:
    def __init__(self):
        self.vector_db = pinecone.Index("wealthwise-context")
        self.embedder = OpenAIEmbeddings()
    
    async def store_interaction(self, user_id: str, interaction: dict):
        # Generate embedding
        text = f"{interaction['query']} {interaction['response']}"
        embedding = await self.embedder.embed(text)
        
        # Store in vector DB with metadata
        self.vector_db.upsert(
            vectors=[{
                "id": f"{user_id}_{timestamp}",
                "values": embedding,
                "metadata": {
                    "user_id": user_id,
                    "agent": interaction['agent'],
                    "timestamp": timestamp,
                    "category": interaction['category']
                }
            }]
        )
    
    async def get_relevant_context(self, user_id: str, query: str, limit: int = 5):
        query_embedding = await self.embedder.embed(query)
        
        results = self.vector_db.query(
            vector=query_embedding,
            filter={"user_id": user_id},
            top_k=limit,
            include_metadata=True
        )
        
        return self._format_context(results)
```

## Security Architecture

### Multi-Layer Security Model

```
┌─────────────────────────────────────────────────────┐
│                  Application Layer                   │
│  • Input Validation  • SQL Injection Prevention     │
│  • XSS Protection    • CSRF Protection              │
└─────────────────────────────────────────────────────┘
                         │
┌─────────────────────────────────────────────────────┐
│                 Authentication Layer                 │
│  • JWT Tokens        • OAuth 2.0                    │
│  • Biometric Auth    • 2FA/MFA                      │
└─────────────────────────────────────────────────────┘
                         │
┌─────────────────────────────────────────────────────┐
│                  Network Layer                       │
│  • TLS 1.3          • Certificate Pinning           │
│  • API Rate Limiting • DDoS Protection              │
└─────────────────────────────────────────────────────┘
                         │
┌─────────────────────────────────────────────────────┐
│                   Data Layer                         │
│  • Encryption at Rest • Field-level Encryption      │
│  • Key Rotation      • Audit Logging                │
└─────────────────────────────────────────────────────┘
```

### Encryption Strategy

```typescript
// Field-level encryption for sensitive data
class EncryptionService {
  private readonly algorithm = 'aes-256-gcm';
  private readonly keyDerivation = 'pbkdf2';
  
  async encryptField(data: string, userId: string): Promise<EncryptedData> {
    const userKey = await this.deriveUserKey(userId);
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(this.algorithm, userKey, iv);
    
    const encrypted = Buffer.concat([
      cipher.update(data, 'utf8'),
      cipher.final()
    ]);
    
    return {
      data: encrypted.toString('base64'),
      iv: iv.toString('base64'),
      tag: cipher.getAuthTag().toString('base64')
    };
  }
}
```

## Scalability Architecture

### Horizontal Scaling Strategy

```
┌─────────────────────────────────────────────────────┐
│                  Load Balancer                       │
│              (Geographic Distribution)               │
└────────────────────┬───────────────────────────────┘
                     │
    ┌────────────────┼────────────────┐
    ▼                ▼                ▼
┌────────┐      ┌────────┐      ┌────────┐
│Region 1│      │Region 2│      │Region 3│
│Mumbai  │      │Chennai │      │Delhi   │
└────┬───┘      └────┬───┘      └────┬───┘
     │               │               │
     ▼               ▼               ▼
  Services        Services        Services
  Cluster         Cluster         Cluster
```

### Caching Strategy

```typescript
// Multi-level caching
class CacheManager {
  private readonly l1Cache = new Map(); // In-memory
  private readonly l2Cache = redis;     // Redis
  private readonly l3Cache = cdn;       // CDN
  
  async get(key: string): Promise<any> {
    // Check L1 (fastest)
    if (this.l1Cache.has(key)) {
      return this.l1Cache.get(key);
    }
    
    // Check L2
    const l2Result = await this.l2Cache.get(key);
    if (l2Result) {
      this.l1Cache.set(key, l2Result);
      return l2Result;
    }
    
    // Check L3
    const l3Result = await this.l3Cache.get(key);
    if (l3Result) {
      await this.l2Cache.set(key, l3Result);
      this.l1Cache.set(key, l3Result);
      return l3Result;
    }
    
    return null;
  }
}
```

## Performance Optimization

### Mobile App Optimization

1. **Lazy Loading**: Load features on-demand
2. **Image Optimization**: WebP format, multiple resolutions
3. **Code Splitting**: Separate bundles for features
4. **Offline First**: Local database sync
5. **Background Sync**: Queue operations when offline

### Backend Optimization

1. **Database Indexing**: Optimized queries
2. **Connection Pooling**: Reuse database connections
3. **Query Optimization**: Aggregation pipelines
4. **Batch Processing**: Bulk operations
5. **Async Processing**: Queue heavy tasks

### AI Service Optimization

1. **Response Streaming**: Stream AI responses
2. **Context Caching**: Cache user context
3. **Model Optimization**: Quantized models
4. **Batch Inference**: Process multiple requests
5. **Edge Deployment**: Reduce latency

## Monitoring & Observability

### Three Pillars of Observability

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Metrics   │     │    Logs     │     │   Traces    │
│ (Prometheus)│     │   (ELK)     │     │  (Jaeger)   │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┴───────────────────┘
                          │
                   ┌──────▼──────┐
                   │  Grafana    │
                   │ Dashboard   │
                   └─────────────┘
```

### Key Metrics

1. **Business Metrics**
   - Daily Active Users
   - Transaction Volume
   - AI Query Volume
   - Feature Adoption

2. **Technical Metrics**
   - API Latency (p50, p95, p99)
   - Error Rate
   - Database Performance
   - Cache Hit Rate

3. **AI Metrics**
   - Response Accuracy
   - Token Usage
   - Context Retrieval Time
   - User Satisfaction

## Disaster Recovery

### Backup Strategy

```
┌─────────────────────────────────────────────┐
│         Production Environment               │
└──────────────────┬──────────────────────────┘
                   │
         ┌─────────┴─────────┐
         ▼                   ▼
┌─────────────────┐ ┌─────────────────┐
│ Real-time Sync  │ │ Daily Snapshots │
│   (Critical)    │ │  (Full Backup)  │
└────────┬────────┘ └────────┬────────┘
         │                   │
         ▼                   ▼
┌─────────────────┐ ┌─────────────────┐
│  Hot Standby    │ │  Cold Storage   │
│   (Primary)     │ │   (Archive)     │
└─────────────────┘ └─────────────────┘
```

### Recovery Procedures

1. **RTO**: 15 minutes (Recovery Time Objective)
2. **RPO**: 5 minutes (Recovery Point Objective)
3. **Automated Failover**: Multi-region setup
4. **Data