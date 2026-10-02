# VEGA AI - Architecture Specification

VEGA AI is a JARVIS-inspired Android voice assistant built with Flutter, Kotlin, and a hybrid AI architecture (Offline local rules/LLM + Online Gemini API).

## 1. Design System & Theme
- **Primary Pink**: `#F73B9A` (Core energetic accent, listening glow, active pulse)
- **Lavender**: `#D9C6FD` (Secondary accent, orbital waves, passive glow, soft highlights)
- **Neutral Light**: `#FAF8FC` / `#FFFFFF` (Clean, subtle cards with glassmorphism touches)
- **Deep Slate/Dark**: `#0D0B14` / `#161224` (Immersive sci-fi JARVIS aesthetic in dark mode)

---

## 2. Directory & Layer Organization

```
lib/
├── app/                  # Application lifecycle, routing, and environment config
├── core/
│   ├── constants/        # Colors, string constants, metrics
│   ├── errors/           # Failure definitions & exceptions
│   ├── models/           # Domain models: VoiceCommand, CommandIntent, ExecutionResult
│   ├── platform/         # MethodChannel constants and bridges
│   └── utils/            # Safe logging, formatting helpers
├── features/
│   ├── assistant/        # Core voice interface & animated circular orb
│   ├── automation/       # Safe app action registry & Android integrations
│   ├── history/          # Activity & command audit log
│   ├── home/             # Main responsive dashboard
│   └── settings/         # Configuration (AI switch, keys, sensitivity)
├── services/
│   ├── ai/               # AI Router, Offline AIService, Online GeminiService
│   ├── audio/            # Earcon playback & audio cues
│   ├── connectivity/     # Network & offline state monitor
│   ├── speech/           # STT & Wake-word detection contracts
│   ├── storage/          # Local persistence contracts
│   └── voice/            # TTS engine interface
└── shared/
    ├── theme/            # Material 3 light/dark themes
    └── widgets/          # Reusable UI components
```

---

## 3. Assistant State Machine

The assistant operates as a state machine:
```
[IDLE] ──(Wake Word / Tap)──> [LISTENING]
  ▲                                │
  │                           (Audio Stream)
  │                                ▼
[SPEAKING] <──(Response)──── [PROCESSING]
```

- **Idle**: Ambient breathing pulse on the orb; awaiting wake-word or user tap.
- **Listening**: Real-time microphone input, expanding wave rings with Primary Pink.
- **Processing**: Rotating Lavender orbital ring, intent classification & AI dispatch.
- **Speaking**: Modulated wave animation corresponding to TTS voice output.

---

## 4. Hybrid AI Routing Architecture

```
User Voice Input
       │
       ▼
 Speech-to-Text (Local/Online)
       │
       ▼
 [AI Router] ──(Connectivity check & Intent Classifier)
       │
       ├──> Device Command / Local Rule ──> [Offline Engine] ──> Fast execution (<100ms)
       │                                                                │
       └──> Conversational / Complex Query ──> [Online Gemini API] ─────┤
                                                                        ▼
                                                             [Execution & Response]
```

1. **Connectivity Check**: If offline, always route to local engine.
2. **Intent Matching**: If input matches registered device actions (e.g., "turn on flashlight", "set volume to 50%"), execute locally without internet latency.
3. **Conversational Synthesis**: Complex reasoning or natural conversation queries are routed to Gemini API.

---

## 5. Security & Safe Action Registry

VEGA AI enforces strict security policies:
- **No Arbitrary Shell Execution**: Commands are matched against a typed, explicit `AppAction` whitelist.
- **Permission Safety Levels**:
  - `Safe`: Read-only or standard operations (e.g. read time, battery level).
  - `NeedsConfirmation`: Destructive or significant actions (e.g. deleting reminders, sending messages) require voice or visual confirmation.
  - `Restricted`: Device security actions (e.g. lock screen settings, factory reset) are strictly blocked.
- **Zero Hardcoded Secrets**: All API keys and credentials are input by the user via secure local storage or environment variables.
